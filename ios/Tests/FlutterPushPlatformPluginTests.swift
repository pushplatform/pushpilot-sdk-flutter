import XCTest
import Flutter
@testable import push_platform_flutter

class FlutterPushPlatformPluginTests: XCTestCase {
    var plugin: FlutterPushPlatformPlugin!
    var mockBinaryMessenger: MockBinaryMessenger!

    override func setUp() {
        super.setUp()
        plugin = FlutterPushPlatformPlugin()
        mockBinaryMessenger = MockBinaryMessenger()

        let mockRegistrar = MockPluginRegistrar(messenger: mockBinaryMessenger)
        plugin.register(with: mockRegistrar)
    }

    override func tearDown() {
        plugin = nil
        mockBinaryMessenger = nil
        super.tearDown()
    }

    func testInitializeWithValidParameters() {
        let expectation = self.expectation(description: "Initialize completes")

        let call = FlutterMethodCall(
            methodName: "initialize",
            arguments: [
                "apiKey": "test-api-key",
                "apiBaseURL": "https://api.test.pushplatform.example",
                "environment": "development",
                "debugMode": true
            ]
        )

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testInitializeWithMissingAPIKey() {
        let expectation = self.expectation(description: "Initialize fails")

        let call = FlutterMethodCall(
            methodName: "initialize",
            arguments: [
                "environment": "production"
            ]
        )

        plugin.handle(call) { result in
            if let error = result as? FlutterError {
                XCTAssertEqual(error.code, "INVALID_ARGUMENTS")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testRequestPermissions() {
        let expectation = self.expectation(description: "Request permissions")

        let call = FlutterMethodCall(methodName: "requestPermissions", arguments: nil)

        plugin.handle(call) { result in
            XCTAssertNotNil(result)
            if let granted = result as? Bool {
                XCTAssertTrue(granted is Bool)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testLoginWithUserId() {
        let expectation = self.expectation(description: "Login completes")

        let call = FlutterMethodCall(
            methodName: "login",
            arguments: ["userId": "test-user-123"]
        )

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testLoginWithoutUserId() {
        let expectation = self.expectation(description: "Login fails")

        let call = FlutterMethodCall(methodName: "login", arguments: nil)

        plugin.handle(call) { result in
            if let error = result as? FlutterError {
                XCTAssertEqual(error.code, "INVALID_ARGUMENTS")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testLogout() {
        let expectation = self.expectation(description: "Logout completes")

        let call = FlutterMethodCall(methodName: "logout", arguments: nil)

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testGetDeviceId() {
        let expectation = self.expectation(description: "Get device ID")

        let call = FlutterMethodCall(methodName: "getDeviceId", arguments: nil)

        plugin.handle(call) { result in
            if let deviceId = result as? String {
                XCTAssertFalse(deviceId.isEmpty)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testGetUserId() {
        let expectation = self.expectation(description: "Get user ID")

        let call = FlutterMethodCall(methodName: "getUserId", arguments: nil)

        plugin.handle(call) { result in
            // User ID may be nil if not logged in
            XCTAssertTrue(result == nil || result is String)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testRegisterForVoIPPushes() {
        let expectation = self.expectation(description: "Register VoIP")

        let call = FlutterMethodCall(methodName: "registerForVoIPPushes", arguments: nil)

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testReportIncomingVoIPCall() {
        let expectation = self.expectation(description: "Report VoIP call")

        let call = FlutterMethodCall(
            methodName: "reportIncomingVoIPCall",
            arguments: [
                "callId": "test-call-123",
                "callerName": "Test Caller"
            ]
        )

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testEndVoIPCall() {
        let expectation = self.expectation(description: "End VoIP call")

        let call = FlutterMethodCall(
            methodName: "endVoIPCall",
            arguments: ["callId": "test-call-123"]
        )

        plugin.handle(call) { result in
            XCTAssertNil(result as? FlutterError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Mock Classes

class MockBinaryMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {
        callback?(nil)
    }

    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil) -> FlutterBinaryMessengerConnection {
        return 0
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

class MockPluginRegistrar: NSObject, FlutterPluginRegistrar {
    let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func messenger() -> FlutterBinaryMessenger {
        return messenger
    }

    func textures() -> FlutterTextureRegistry {
        fatalError("Not implemented")
    }

    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {}

    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {}

    func publish(_ value: NSObject) {}

    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {}

    func addApplicationDelegate(_ delegate: FlutterPlugin) {}

    func lookupKey(forAsset asset: String) -> String {
        return asset
    }

    func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
        return "\(package)/\(asset)"
    }
}
