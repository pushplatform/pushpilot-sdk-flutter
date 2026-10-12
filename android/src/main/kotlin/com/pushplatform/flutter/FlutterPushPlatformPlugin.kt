package com.pushplatform.flutter

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import com.pushplatform.sdk.PushPlatform
import com.pushplatform.sdk.PushPlatformDelegate
import com.pushplatform.sdk.Environment
import com.pushplatform.sdk.models.SdkError
import com.pushplatform.sdk.notifications.ParsedNotification
import com.pushplatform.sdk.core.UserManager
import com.pushplatform.sdk.utils.PermissionChecker

/// Flutter plugin for Push Platform Android SDK
///
/// This plugin acts as a thin bridge between Flutter (Dart) and the native Android SDK.
/// All business logic, retry, deduplication, and token management happen in the Android SDK.
///
/// SECURITY: Raw FCM tokens are NEVER passed to Dart.
class FlutterPushPlatformPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var context: Context
    private lateinit var sdk: PushPlatform
    private lateinit var methodChannel: MethodChannel
    private lateinit var pushEventChannel: EventChannel
    private lateinit var callEventChannel: EventChannel
    private lateinit var stateEventChannel: EventChannel

    private var pushEventSink: EventChannel.EventSink? = null
    private var callEventSink: EventChannel.EventSink? = null
    private var stateEventSink: EventChannel.EventSink? = null

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        sdk = PushPlatform.getInstance()

        methodChannel = MethodChannel(binding.binaryMessenger, "com.pushplatform/sdk")
        pushEventChannel = EventChannel(binding.binaryMessenger, "com.pushplatform/push_events")
        callEventChannel = EventChannel(binding.binaryMessenger, "com.pushplatform/call_events")
        stateEventChannel = EventChannel(binding.binaryMessenger, "com.pushplatform/state_events")

        methodChannel.setMethodCallHandler(this)
        pushEventChannel.setStreamHandler(PushEventStreamHandler(this))
        callEventChannel.setStreamHandler(CallEventStreamHandler(this))
        stateEventChannel.setStreamHandler(StateEventStreamHandler(this))

        // Set delegate to receive SDK callbacks
        sdk.delegate = DelegateImpl(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pendingPermissionResult?.error("DETACHED", "Flutter engine detached", null)
        pendingPermissionResult = null
        methodChannel.setMethodCallHandler(null)
        pushEventChannel.setStreamHandler(null)
        callEventChannel.setStreamHandler(null)
        stateEventChannel.setStreamHandler(null)
        sdk.delegate = null
    }

    // ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        pendingPermissionResult?.error("NO_ACTIVITY", "Activity detached", null)
        pendingPermissionResult = null
        activity = null
    }

    // MethodChannel.MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "requestPermissions" -> handleRequestPermissions(result)
            "login" -> handleLogin(call, result)
            "logout" -> handleLogout(result)
            "getDeviceId" -> result.success(sdk.getInstallationId())
            "getUserId" -> result.success(null) // SDK doesn't expose current user ID
            else -> result.notImplemented()
        }
    }

    // MethodCall handlers

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGUMENTS", "Arguments must be a map", null)
            return
        }

        val apiKey = args["apiKey"] as? String
        val environmentStr = args["environment"] as? String

        if (apiKey == null || environmentStr == null) {
            result.error("INVALID_ARGUMENTS", "Missing required arguments: apiKey, environment", null)
            return
        }

        val apiBaseURL = args["apiBaseURL"] as? String
        val applicationId = args["applicationId"] as? String
        if (apiBaseURL.isNullOrBlank() || applicationId.isNullOrBlank()) {
            result.error("INVALID_ARGUMENTS", "apiBaseURL and applicationId are required", null)
            return
        }
        val debugMode = args["debugMode"] as? Boolean ?: false

        // Map environment string to SDK enum
        val environment = when (environmentStr.lowercase()) {
            "production" -> Environment.PRODUCTION
            "development", "sandbox" -> Environment.DEVELOPMENT
            else -> {
                result.error(
                    "INVALID_ARGUMENTS",
                    "Invalid environment: $environmentStr. Use 'production' or 'development'.",
                    null
                )
                return
            }
        }

        try {
            sdk.configure(
                context = context,
                apiKey = apiKey,
                environment = environment,
                debugMode = debugMode,
                apiBaseUrl = apiBaseURL,
                applicationId = applicationId
            ) { configurationResult ->
                mainHandler.post {
                    configurationResult.fold(
                        onSuccess = { result.success(null) },
                        onFailure = { error ->
                            stateEventSink?.success("error")
                            result.error(
                                if (error is SdkError) mapSdkErrorCode(error) else "CONFIGURATION_FAILED",
                                "PushPilot initialization failed", null
                            )
                        }
                    )
                }
            }
        } catch (e: Exception) {
            result.error("CONFIGURATION_FAILED", e.message ?: "Unknown error", null)
        }
    }

    private fun handleRequestPermissions(result: MethodChannel.Result) {
        if (!sdk.isConfigured()) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        // Check if already granted
        if (sdk.hasNotificationPermission()) {
            stateEventSink?.success("permissionsGranted")
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_REQUEST_IN_PROGRESS", "A permission request is already pending", null)
            return
        }
        pendingPermissionResult = result
        sdk.requestNotificationPermission(act)
    }

    private fun handleLogin(call: MethodCall, result: MethodChannel.Result) {
        if (!sdk.isConfigured()) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGUMENTS", "Arguments must be a map", null)
            return
        }

        val userId = args["userId"] as? String
        if (userId == null) {
            result.error("INVALID_ARGUMENTS", "Missing required argument: userId", null)
            return
        }

        sdk.login(userId) { loginResult ->
            mainHandler.post {
                when (loginResult) {
                    is UserManager.Result.Success -> {
                        stateEventSink?.success("loggedIn")
                        result.success(sdk.getInstallationId())
                    }
                    is UserManager.Result.Failure -> {
                        result.error(
                            mapSdkErrorCode(loginResult.error),
                            loginResult.error.message,
                            null
                        )
                    }
                }
            }
        }
    }

    private fun handleLogout(result: MethodChannel.Result) {
        if (!sdk.isConfigured()) {
            result.error("NOT_INITIALIZED", "SDK not initialized. Call initialize() first.", null)
            return
        }

        sdk.logout { logoutResult ->
            mainHandler.post {
                when (logoutResult) {
                    is UserManager.Result.Success -> {
                        stateEventSink?.success("loggedOut")
                        result.success(null)
                    }
                    is UserManager.Result.Failure -> {
                        result.error(
                            mapSdkErrorCode(logoutResult.error),
                            logoutResult.error.message,
                            null
                        )
                    }
                }
            }
        }
    }

    // PluginRegistry.RequestPermissionsResultListener

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PermissionChecker.REQUEST_CODE_NOTIFICATION_PERMISSION) return false
        sdk.onRequestPermissionsResult(requestCode, grantResults)
        return true
    }

    // Event serialization

    private fun serializeNotification(notification: ParsedNotification): Map<String, Any?> {
        return mapOf(
            "messageId" to notification.eventId,
            "title" to notification.title,
            "body" to notification.body,
            "data" to notification.customData,
            "type" to if (notification.title == null && notification.body == null) "silent" else "normal",
            "receivedAt" to System.currentTimeMillis()
        )
    }

    private fun serializeCallInfo(notification: ParsedNotification): Map<String, Any?> {
        return mapOf(
            "callId" to notification.callId,
            "callerId" to (notification.customData["callerId"] ?: ""),
            "callerName" to notification.title,
            "metadata" to notification.customData,
            "receivedAt" to System.currentTimeMillis()
        )
    }

    // Error code mapping

    private fun mapSdkErrorCode(error: SdkError): String {
        return when (error) {
            is SdkError.NotConfigured -> "NOT_INITIALIZED"
            is SdkError.NetworkError -> "NETWORK_ERROR"
            is SdkError.ApiError -> "API_ERROR"
            is SdkError.InvalidToken -> "INVALID_TOKEN"
            is SdkError.MaxRetriesExceeded -> "MAX_RETRIES_EXCEEDED"
            is SdkError.StorageError -> "STORAGE_ERROR"
        }
    }

    // Delegate Implementation

    private class DelegateImpl(private val plugin: FlutterPushPlatformPlugin) : PushPlatformDelegate {
        override fun didInitialize(installationId: String) {
            plugin.mainHandler.post { plugin.stateEventSink?.success("initialized") }
        }

        override fun didUpdateFcmToken() {
            // SECURITY: Token is NEVER passed to Dart
            plugin.mainHandler.post { plugin.stateEventSink?.success("registered") }
        }

        override fun didFailToRegisterFcmToken(error: SdkError) {
            plugin.mainHandler.post { plugin.stateEventSink?.success("error") }
        }

        override fun didReceiveNotification(notification: ParsedNotification, isInForeground: Boolean) {
            plugin.mainHandler.post {
                // Check if this is a call notification (high-priority)
                if (notification.callId != null) {
                    val payload = plugin.serializeCallInfo(notification)
                    plugin.callEventSink?.success(payload)
                } else {
                    val payload = plugin.serializeNotification(notification)
                    plugin.pushEventSink?.success(payload)
                }
            }
        }

        override fun onNotificationPermissionResult(granted: Boolean) {
            plugin.mainHandler.post {
                if (granted) {
                    plugin.stateEventSink?.success("permissionsGranted")
                } else {
                    plugin.stateEventSink?.success("permissionsDenied")
                }
                plugin.pendingPermissionResult?.success(granted)
                plugin.pendingPermissionResult = null
            }
        }
    }

    // Event Stream Handlers

    private class PushEventStreamHandler(private val plugin: FlutterPushPlatformPlugin) :
        EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            plugin.pushEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            plugin.pushEventSink = null
        }
    }

    private class CallEventStreamHandler(private val plugin: FlutterPushPlatformPlugin) :
        EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            plugin.callEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            plugin.callEventSink = null
        }
    }

    private class StateEventStreamHandler(private val plugin: FlutterPushPlatformPlugin) :
        EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            plugin.stateEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            plugin.stateEventSink = null
        }
    }
}
