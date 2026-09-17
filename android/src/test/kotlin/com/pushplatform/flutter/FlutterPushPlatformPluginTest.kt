package com.pushplatform.flutter

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.junit.MockitoJUnitRunner
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.verify

@RunWith(MockitoJUnitRunner::class)
class FlutterPushPlatformPluginTest {
    @Mock
    private lateinit var mockContext: Context

    @Mock
    private lateinit var mockResult: MethodChannel.Result

    private lateinit var plugin: FlutterPushPlatformPlugin

    @Before
    fun setUp() {
        plugin = FlutterPushPlatformPlugin()
    }

    @Test
    fun `initialize with valid parameters succeeds`() {
        val arguments = mapOf(
            "apiKey" to "test-api-key",
            "apiBaseURL" to "https://api.test.pushplatform.example",
            "environment" to "development",
            "debugMode" to true
        )
        val call = MethodCall("initialize", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(null)
        verify(mockResult, never()).error(any(), any(), any())
    }

    @Test
    fun `initialize with missing apiKey fails`() {
        val arguments = mapOf(
            "environment" to "production"
        )
        val call = MethodCall("initialize", arguments)

        plugin.onMethodCall(call, mockResult)

        val errorCodeCaptor = argumentCaptor<String>()
        verify(mockResult).error(errorCodeCaptor.capture(), any(), any())
        assert(errorCodeCaptor.firstValue == "INVALID_ARGUMENTS")
    }

    @Test
    fun `initialize with empty apiKey fails`() {
        val arguments = mapOf(
            "apiKey" to "",
            "environment" to "production"
        )
        val call = MethodCall("initialize", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("INVALID_API_KEY"), any(), any())
    }

    @Test
    fun `requestPermissions returns boolean result`() {
        val call = MethodCall("requestPermissions", null)

        plugin.onMethodCall(call, mockResult)

        val resultCaptor = argumentCaptor<Boolean>()
        verify(mockResult).success(resultCaptor.capture())
        assert(resultCaptor.firstValue is Boolean)
    }

    @Test
    fun `login with userId succeeds`() {
        val arguments = mapOf("userId" to "test-user-123")
        val call = MethodCall("login", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(any())
        verify(mockResult, never()).error(any(), any(), any())
    }

    @Test
    fun `login without userId fails`() {
        val call = MethodCall("login", null)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("INVALID_ARGUMENTS"), any(), any())
    }

    @Test
    fun `login with empty userId fails`() {
        val arguments = mapOf("userId" to "")
        val call = MethodCall("login", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("INVALID_USER_ID"), any(), any())
    }

    @Test
    fun `logout succeeds`() {
        val call = MethodCall("logout", null)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(null)
        verify(mockResult, never()).error(any(), any(), any())
    }

    @Test
    fun `getDeviceId returns non-empty string`() {
        val call = MethodCall("getDeviceId", null)

        plugin.onMethodCall(call, mockResult)

        val resultCaptor = argumentCaptor<String>()
        verify(mockResult).success(resultCaptor.capture())
        assert(resultCaptor.firstValue.isNotEmpty())
    }

    @Test
    fun `getUserId returns string or null`() {
        val call = MethodCall("getUserId", null)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(any())
    }

    @Test
    fun `reportIncomingCall with valid parameters succeeds`() {
        val arguments = mapOf(
            "callId" to "test-call-123",
            "callerName" to "Test Caller"
        )
        val call = MethodCall("reportIncomingCall", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(null)
        verify(mockResult, never()).error(any(), any(), any())
    }

    @Test
    fun `reportIncomingCall without callId fails`() {
        val arguments = mapOf("callerName" to "Test Caller")
        val call = MethodCall("reportIncomingCall", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("INVALID_ARGUMENTS"), any(), any())
    }

    @Test
    fun `endCall with callId succeeds`() {
        val arguments = mapOf("callId" to "test-call-123")
        val call = MethodCall("endCall", arguments)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(null)
        verify(mockResult, never()).error(any(), any(), any())
    }

    @Test
    fun `endCall without callId fails`() {
        val call = MethodCall("endCall", null)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("INVALID_ARGUMENTS"), any(), any())
    }

    @Test
    fun `unknown method returns notImplemented`() {
        val call = MethodCall("unknownMethod", null)

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).notImplemented()
    }

    @Test
    fun `multiple initialize calls handle gracefully`() {
        val arguments = mapOf(
            "apiKey" to "test-api-key",
            "environment" to "development"
        )
        val call = MethodCall("initialize", arguments)

        // First call
        plugin.onMethodCall(call, mockResult)
        verify(mockResult).success(null)

        // Second call
        val mockResult2 = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult2)
        verify(mockResult2).success(null)
    }
}
