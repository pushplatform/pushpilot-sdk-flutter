import Flutter
import UIKit
import UserNotifications
import PushPlatformSDK

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
    fileprivate var openedEventSink: FlutterEventSink?
    fileprivate var willDisplayEventSink: FlutterEventSink?
    fileprivate var tokenEventSink: FlutterEventSink?
    fileprivate var willDisplayObserved = false
    private var pendingDisplays: [String: NotificationDisplayEvent] = [:]

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
        registrar.addApplicationDelegate(instance)

        pushEventChannel.setStreamHandler(PushEventStreamHandler(instance))
        voipEventChannel.setStreamHandler(VoIPEventStreamHandler(instance))
        stateEventChannel.setStreamHandler(StateEventStreamHandler(instance))
        FlutterEventChannel(name: "com.pushplatform/notification_opened", binaryMessenger: registrar.messenger()).setStreamHandler(OpenedEventStreamHandler(instance))
        FlutterEventChannel(name: "com.pushplatform/notification_will_display", binaryMessenger: registrar.messenger()).setStreamHandler(WillDisplayEventStreamHandler(instance))
        FlutterEventChannel(name: "com.pushplatform/token_events", binaryMessenger: registrar.messenger()).setStreamHandler(TokenEventStreamHandler(instance))

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
        case "getDeviceToken":
            result(sdk?.getDeviceToken())
        case "getPermissionStatus":
            handlePermissionStatus(result: result)
        case "setNotificationWillDisplayObserved":
            willDisplayObserved = call.arguments as? Bool ?? false
            result(nil)
        case "completeNotificationDisplay":
            completeDisplay(call)
            result(nil)
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
              let applicationId = args["applicationId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "applicationId is required", details: nil))
            return
        }
        let debugMode = args["debugMode"] as? Bool ?? false
        let fallback = (args["foregroundBannerFallback"] as? NSNumber)?.doubleValue ?? 0
        guard fallback.isFinite, fallback >= 0 else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "foregroundBannerFallback must be a non-negative number of seconds", details: nil))
            return
        }
        var options = PushPlatform.InitializeOptions(applicationId: applicationId, url: args["url"] as? String, debugMode: debugMode, foregroundBannerFallback: fallback)
        if let name = (args["environment"] as? String)?.lowercased() {
            switch name {
            case "production": options.environment = .production
            case "development", "sandbox": options.environment = .development
            default:
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid environment. Use 'production' or 'development'.", details: nil))
                return
            }
        }

        sdk = PushPlatform.shared
        sdk?.delegate = self
        sdk?.initialize(options) { configurationResult in
            switch configurationResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(FlutterError(code: self.mapErrorCode(error), message: "PushPilot initialization failed", details: nil))
            }
        }

        // Note: VoIP registration happens automatically after configure()
        // PushKitManager is initialized in PushPlatform init and registers immediately

    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        sdk?.didRegisterAPNsToken(deviceToken)
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        sdk?.didFailToRegisterAPNs(error)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let sdk = sdk else { completionHandler([]); return }
        sdk.handleForegroundNotification(notification, completionHandler: completionHandler)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let sdk = sdk else { completionHandler(); return }
        sdk.handleNotificationResponse(response, completionHandler: completionHandler)
    }

    private func handleRequestPermissions(result: @escaping FlutterResult) {
        guard sdk?.getInstallationID() != nil else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Await initialize() first", details: nil))
            return
        }
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
                        self.sdk?.refreshMetadata()
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

    private func handlePermissionStatus(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: String
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                status = "granted"
            case .denied:
                status = "denied"
            case .notDetermined:
                status = "not-determined"
            @unknown default:
                status = "not-determined"
            }
            DispatchQueue.main.async { result(status) }
        }
    }

    private func completeDisplay(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else { return }
        guard let event = pendingDisplays.removeValue(forKey: id) else { return }
        if args["prevented"] as? Bool == true {
            event.preventDefault()
        }
        event.finish()
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

        sdk.login(userID: userId, metadata: args["metadata"] as? [String: Any]) { loginResult in
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
        dict["messageId"] = notification.eventID ?? notification.callID ?? "notification"

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
        openedEventSink?(serializeNotification(notification))
    }

    public func notificationWillDisplay(_ event: NotificationDisplayEvent) {
        guard willDisplayObserved else { return }
        let displayId = UUID().uuidString
        pendingDisplays[displayId] = event
        event.deferDecision()
        willDisplayEventSink?([
            "id": displayId,
            "notification": serializeNotification(event.notification)
        ])
    }

    public func didUpdateDeviceToken(_ token: String) {
        tokenEventSink?(token)
    }

    public func didReceiveIncomingCall(callID: String, callerName: String, metadata: [String: Any]) {
        let payload = serializeCallInfo(callID: callID, callerName: callerName, metadata: metadata)
        voipEventSink?(payload)
    }

    // SECURITY: Token methods are NEVER exposed to Dart
    // Token registration happens entirely in the native SDK
    public func didUpdateAPNsToken() {
        if let token = sdk?.getDeviceToken() {
            tokenEventSink?(token)
        }
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

class OpenedEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?
    init(_ plugin: FlutterPushPlatformPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.openedEventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.openedEventSink = nil
        return nil
    }
}

class WillDisplayEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?
    init(_ plugin: FlutterPushPlatformPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.willDisplayEventSink = events
        plugin?.willDisplayObserved = true
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.willDisplayEventSink = nil
        plugin?.willDisplayObserved = false
        return nil
    }
}

class TokenEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterPushPlatformPlugin?
    init(_ plugin: FlutterPushPlatformPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.tokenEventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.tokenEventSink = nil
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
