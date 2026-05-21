package com.example.ai_chatbot

import android.os.Handler
import android.os.Looper
import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Dedicated overlay WebSocket — connects to /overlay/chat only (not main /chat).
 */
class OverlaySocketManager(
    private var backendUrl: String,
    private val onStatus: (String) -> Unit,
    private val onChunk: (delta: String, full: String) -> Unit,
    private val onDone: (full: String) -> Unit,
    private val onError: (String) -> Unit,
    private val onContextDetected: (detectedItems: List<String>, suggestions: List<Pair<String, String>>) -> Unit
) {
    companion object {
        private const val TAG = "AURA_OVERLAY_WS"
        const val CONVERSATION_ID = "aura_overlay"
        private const val CONNECT_TIMEOUT_MS = 8000L
        private const val RECONNECT_DELAY_MS = 3000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val reconnectHandler = Handler(Looper.getMainLooper())
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .connectTimeout(15, TimeUnit.SECONDS)
        .build()

    private var socket: WebSocket? = null
    private var connected = false
    private var reconnecting = false
    private var pendingPayload: String? = null
    private val replyBuffer = StringBuilder()

    fun updateBackendUrl(url: String) {
        if (url.isNotEmpty() && url != backendUrl) {
            backendUrl = url
            disconnect()
        }
    }

    private fun wsUrl(): String {
        return backendUrl
            .replace("http://", "ws://")
            .replace("https://", "wss://")
            .trimEnd('/') + "/overlay"
    }

    fun ensureConnected() {
        if (connected && socket != null) return
        if (reconnecting) return
        reconnecting = true
        val request = Request.Builder().url(wsUrl()).build()
        Log.d(TAG, "Connecting ${wsUrl()}")
        try {
            socket?.close(1000, "reconnect")
            socket = client.newWebSocket(request, listener)
            mainHandler.postDelayed({
                if (!connected && pendingPayload != null) {
                    reconnecting = false
                    onError("AURA overlay lost connection. Retrying…")
                    scheduleReconnect()
                }
            }, CONNECT_TIMEOUT_MS)
        } catch (e: Exception) {
            reconnecting = false
            onError("Cannot reach AURA backend: ${e.message}")
        }
    }

    fun send(payload: JSONObject) {
        val json = payload.toString()
        replyBuffer.setLength(0)
        if (connected && socket != null) {
            val sent = socket?.send(json) ?: false
            if (sent) {
                Log.d(TAG, "Sent overlay message")
                return
            }
        }
        pendingPayload = json
        onStatus("Connecting to AURA overlay…")
        ensureConnected()
    }

    fun disconnect() {
        reconnectHandler.removeCallbacksAndMessages(null)
        try {
            socket?.close(1000, "overlay stop")
        } catch (_: Exception) {}
        socket = null
        connected = false
        reconnecting = false
        pendingPayload = null
    }

    private fun scheduleReconnect() {
        reconnectHandler.removeCallbacksAndMessages(null)
        reconnectHandler.postDelayed({
            reconnecting = false
            ensureConnected()
        }, RECONNECT_DELAY_MS)
    }

    private val listener = object : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            connected = true
            reconnecting = false
            Log.d(TAG, "Overlay WebSocket open")
            pendingPayload?.let {
                webSocket.send(it)
                pendingPayload = null
            }
        }

        override fun onMessage(webSocket: WebSocket, text: String) {
            try {
                val obj = JSONObject(text)
                if (obj.optBoolean("done", false)) {
                    val full = replyBuffer.toString()
                    mainHandler.post { onDone(full) }
                    return
                }
                when (obj.optString("type")) {
                    "status" -> mainHandler.post { onStatus(obj.optString("content", "")) }
                    "chunk" -> {
                        val delta = obj.optString("content", "")
                        replyBuffer.append(delta)
                        val full = replyBuffer.toString()
                        mainHandler.post { onChunk(delta, full) }
                    }
                    "context_detected" -> {
                        val detectedJson = obj.optJSONArray("detected_items")
                        val suggestionsJson = obj.optJSONArray("suggestions")
                        val detected = mutableListOf<String>()
                        val suggestions = mutableListOf<Pair<String, String>>()
                        if (detectedJson != null) {
                            for (i in 0 until detectedJson.length()) {
                                detected.add(detectedJson.optString(i))
                            }
                        }
                        if (suggestionsJson != null) {
                            for (i in 0 until suggestionsJson.length()) {
                                val sugObj = suggestionsJson.optJSONObject(i)
                                if (sugObj != null) {
                                    val label = sugObj.optString("label", "")
                                    val prompt = sugObj.optString("prompt", "")
                                    suggestions.add(Pair(label, prompt))
                                } else {
                                    val fallback = suggestionsJson.optString(i, "")
                                    suggestions.add(Pair(fallback, fallback))
                                }
                            }
                        }
                        mainHandler.post { onContextDetected(detected, suggestions) }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Parse error: ${e.message}")
            }
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            connected = false
            reconnecting = false
            Log.e(TAG, "WS failure: ${t.message}")
            val pending = pendingPayload
            if (pending != null) {
                pendingPayload = null
                mainHandler.post { onError("AURA overlay lost connection. Retrying…") }
                scheduleReconnect()
            } else {
                mainHandler.post { onError("Connection lost. Tap send to retry.") }
            }
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            connected = false
            reconnecting = false
            if (pendingPayload != null) scheduleReconnect()
        }
    }
}
