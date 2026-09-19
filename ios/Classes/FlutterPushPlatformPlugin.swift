import Flutter
import UIKit
import PushPlatformSDK
import UserNotifications

/// Flutter plugin for Push Platform iOS SDK
///
/// This plugin acts as a thin bridge between Flutter (Dart) and the native iOS SDK.
/// All business logic, retry, deduplication, and token management happen in PushPlatformSDK.
///
/// SECURITY: Raw APNs/VoIP tokens are NEVER passed to Dart.
public class FlutterPushPlatformPlugin: NSObject, FlutterPlugin {
    private var sdk: PushPlatform?
    private var methodChannel: FlutterMethodChannel!
    private var pushEventChannel: FlutterEventChannel!
    private var voipEventChannel: FlutterEventChannel!
    private var stateEventChannel: FlutterEventChannel!

    fileprivate var pushEventSink: FlutterEventSink?
    fileprivate var voipEventSink: FlutterEventSink?
    fileprivate var stateEventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.pushplatform/sdk",
            binaryMessenger: registrar.messenger()
        )
        let pushEventChannel = FlutterEventChannel(
            name: "com.pushplatform/push_events",
            binaryMessenger: registrar.messenger()
        )
        let voipEventChannel = FlutterEventChannel(
            name: "com.pushplatform/voip_events",
            binaryMessenger: registrar.messenger()
        )
        let stateEventChannel = FlutterEventChannel(
            name: "com.pushplatform/state_events",
            binaryMessenger: registrar.messenger()
        )

        let instance = FlutterPushPlatformPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        pushEventChannel.setStreamHandler(PushEventStreamHandler(instance))
        voipEventChannel.setStreamHandler(VoIPEventStreamHandler(instance))
        stateEventChannel.setStreamHandler(StateEventStreamHandler(instance))

        instance.methodChannel = methodChannel
        instance.pushEventChannel = pushEventChannel
        instance.voipEventChannel = voipEventChannel
        instance.stateEventChannel = stateEventChannel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "requestPermissions":
            handleRequestPermissions(result: result)
        case "login":
            handleLogin(call, result: result)
        case "logout":
            handleLogout(result: result)
        case "registerForVoIP":
            handleRegisterVoIP(result: result)
        case "getDeviceId":
            result(sdk?.getInstallationID()?.uuidString)
        case "getUserId":
            // UserManager doesn't expose userId getter - returning nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let apiKey = args["apiKey"] as? String,
              let environmentStr = args["environment"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing required arguments: apiKey, environment",
                details: nil
            ))
            return
        }

        let apiBaseURL = args["apiBaseURL"] as? String ?? "https://api.pushplatform.example"
        let debugMode = args["debugMode"] as? Bool ?? false

        // Map environment string to SDK enum
        let environment: Environment
        switch environmentStr.lowercased() {
        case "production":
            environment = .production
        case "development", "sandbox":
            environment = .development
        default:
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid environment: \(environmentStr). Use 'production' or 'development'.",
                details: nil
            ))
            return
        }

        // Initialize native SDK
        sdk = PushPlatform.shared
        sdk?.delegate = self

        sdk?.configure(
            apiKey: apiKey,
            apiBaseURL: apiBaseURL,
            environment: environment,
            debugMode: debugMode
        )

        // Note: VoIP registration happens automatically after configure()
        // PushKitManager is initialized in PushPlatform init and registers immediately

        result(nil)
    }

    private func handleRequestPermissions(result: @escaping FlutterResult) {
        // SDK doesn't expose requestAuthorization - call UNUserNotificationCenter directly
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(
                            code: "PERMISSION_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    } else {
                        if granted {
                            self.stateEventSink?("permissionsGranted")
                            // Register for remote notifications
                            UIApplication.shared.registerForRemoteNotifications()
                        } else {
                            self.stateEventSink?("permissionsDenied")
                        }
                        result(granted)
                    }
                }
            }
        } else {
            // iOS 9 fallback
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
            result(true)
        }
    }

    private func handleLogin(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let sdk = sdk else {
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "SDK not initialized. Call initialize() first.",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing required argument: userId",
                details: nil
            ))
            return
        }

        sdk.login(userID: userId) { loginResult in
            switch loginResult {
            case .success:
                self.stateEventSink?("loggedIn")
                // Return installation ID as "deviceId"
                result(sdk.getInstallationID()?.uuidString)
            case .failure(let error):
                result(FlutterError(
                    code: self.mapErrorCode(error),
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    private func handleLogout(result: @escaping FlutterResult) {
        guard let sdk = sdk else {
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "SDK not initialized. Call initialize() first.",
                details: nil
            ))
            return
        }

        sdk.logout { logoutResult in
            switch logoutResult {
            case .success:
                self.stateEventSink?("loggedOut")
                result(nil)
            case .failure(let error):
                result(FlutterError(
                    code: self.mapErrorCode(error),
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    private func handleRegisterVoIP(result: @escaping FlutterResult) {
        // VoIP registration happens automatically in SDK init
        // PushKitManager registers for VoIP push immediately upon creation
        // This method is a no-op, but kept for API compatibility
        result(nil)
    }

    // MARK: - Error Mapping

    private func mapErrorCode(_ error: SDKError) -> String {
        switch error {
        case .notConfigured:
            return "NOT_INITIALIZED"
        case .invalidAPIKey:
            return "INVALID_CREDENTIALS"
        case .networkError:
            return "NETWORK_ERROR"
        case .apiError:
            return "API_ERROR"
        case .invalidToken:
            return "INVALID_TOKEN"
        case .maxRetriesExceeded:
            return "MAX_RETRIES_EXCEEDED"
        case .keychainAccessDenied:
            return "KEYCHAIN_ACCESS_DENIED"
        }
    }

    // MARK: - Event Serialization

    private func serializeNotification(_ notification: ParsedNotification) -> [String: Any] {
        var dict: [String: Any] = [:]

        if let title = notification.title {
            dict["title"] = title
        }
        if let body = notification.body {
            dict["body"] = body
        }
        if let eventID = notification.eventID {
            dict["messageId"] = eventID
        }

        // Sanitize customData for JSON serialization
        dict["data"] = sanitizeForJSON(notification.customData)

        // Determine type based on presence of alert fields
        let hasAlert = notification.title != nil || notification.body != nil
        dict["type"] = hasAlert ? "normal" : "silent"

        dict["receivedAt"] = Int(Date().timeIntervalSince1970 * 1000)

        return dict
    }

    private func serializeCallInfo(callID: String, callerName: String, metadata: [String: Any]) -> [String: Any] {
        var dict: [String: Any] = [
            "callId": callID,
            "callerId": callID, // Use callID as callerId since SDK doesn't separate them
            "callerName": callerName,
            "receivedAt": Int(Date().timeIntervalSince1970 * 1000)
        ]

        // Sanitize metadata for JSON serialization
        dict["metadata"] = sanitizeForJSON(metadata)

        return dict
    }

    /// Sanitize [String: Any] dictionary for JSON serialization
    /// Removes non-JSON-serializable types (NSDate, NSData, custom objects)
    private func sanitizeForJSON(_ dict: [String: Any]) -> [String: Any] {
        var sanitized: [String: Any] = [:]

        for (key, value) in dict {
            if let stringValue = value as? String {
                sanitized[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                // NSNumber can be Bool, Int, Double
                sanitized[key] = numberValue
            } else if let arrayValue = value as? [Any] {
                sanitized[key] = sanitizeArray(arrayValue)
            } else if let dictValue = value as? [String: Any] {
                sanitized[key] = sanitizeForJSON(dictValue)
            } else if value is NSNull {
                sanitized[key] = NSNull()
            }
            // Skip NSDate, NSData, custom objects
        }

        return sanitized
    }

    private func sanitizeArray(_ array: [Any]) -> [Any] {
        return array.compactMap { value -> Any? in
            if let stringValue = value as? String {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue
            } else if let arrayValue = value as? [Any] {
                return sanitizeArray(arrayValue)
            } else if let dictValue = value as? [String: Any] {
                return sanitizeForJSON(dictValue)
            } else if value is NSNull {
                return NSNull()
            }
            return nil // Skip non-serializable
        }
    }
}

// MARK: - PushPlatformDelegate

extension FlutterPushPlatformPlugin: PushPlatformDelegate {
    public func didInitialize(installationID: UUID) {
        stateEventSink?("initialized")
    }

    public func didRegisterTokens() {
        stateEventSink?("registered")
    }

    public func didFailRegisterTokens(error: SDKError) {
        // Report error via state channel
        stateEventSink?("error")
    }

    public func didReceiveNotification(_ notification: ParsedNotification, context: NotificationContext) {
        let payload = serializeNotification(notification)
        pushEventSink?(payload)
    }

    public func didOpenNotification(_ notification: ParsedNotification, action: String?, context: NotificationContext) {
        // Notification opened - same as received for Flutter layer
        let payload = serializeNotification(notification)
        pushEventSink?(payload)
    }

    public func didReceiveIncomingCall(callID: String, callerName: String, metadata: [String: Any]) {
        let payload = serializeCallInfo(callID: callID, callerName: callerName, metadata: metadata)
        voipEventSink?(payload)
    }

    // SECURITY: Token methods are NEVER exposed to Dart
    // Token registration happens entirely in the native SDK
    public func didUpdateAPNsToken() {
        // Token sent to backend by native SDK
        // NOT forwarded to Dart
    }

    public func didUpdateVoIPToken() {
        // VoIP token sent to backend by native SDK
        // NOT forwarded to Dart
    }
}

// MARK: - Event Stream Handlers

class PushEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?

    init(_ plugin: FlutterPushPlatformPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.pushEventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.pushEventSink = nil
        return nil
    }
}

class VoIPEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?

    init(_ plugin: FlutterPushPlatformPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.voipEventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.voipEventSink = nil
        return nil
    }
}

class StateEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?

    init(_ plugin: FlutterPushPlatformPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.stateEventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.stateEventSink = nil
        return nil
    }
}
