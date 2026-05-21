package com.example.ai_chatbot

import android.animation.ValueAnimator
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Base64
import android.util.DisplayMetrics
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

class AuraForegroundService : Service() {

    private lateinit var windowManager: WindowManager
    private var bubbleView: View? = null
    private var chatView: View? = null

    private var bubbleParams: WindowManager.LayoutParams? = null
    private var chatParams: WindowManager.LayoutParams? = null

    private var backendUrl = "https://vijayadhith7-aura-backend.hf.space"

    private lateinit var messageContainer: LinearLayout
    private lateinit var chatScrollView: ScrollView
    private lateinit var inputField: EditText
    private var sendBtn: Button? = null

    private var wakeLock: PowerManager.WakeLock? = null
    private var overlaySocket: OverlaySocketManager? = null
    private var currentAssistantBubbleId: Int? = null
    private var isSending = false
    private var assistantMode = "quick"
    private var lastSendClickMs = 0L

    private val httpClient = okhttp3.OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(45, TimeUnit.SECONDS)
        .build()

    // MediaProjection screen analysis fields
    private var mediaProjection: MediaProjection? = null
    private var hasActiveProjection = false
    private var lastCapturedScreenshotBase64: String? = null

    // Idle pulse animator
    private var bubblePulseAnimator: ValueAnimator? = null

    companion object {
        private const val TAG = "AURA_SERVICE"
        private const val CHANNEL_ID = "aura_overlay_channel"
        private const val NOTIFICATION_ID = 1001
        private const val CORE_IMAGE_ID = 1002
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AURA Overlay Service Created")
        
        // Acquire WakeLock to prevent system from killing background process
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Aura:OverlayWakeLock").apply {
                acquire()
            }
            Log.d(TAG, "WakeLock acquired successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        assistantMode = getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
            .getString("overlay_assistant_mode", "quick") ?: "quick"

        initOverlaySocket()

        try {
            setupNotification()
            setupFloatingLayouts()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup overlay: ${e.message}")
            stopSelf()
            return
        }
    }

    private fun initOverlaySocket() {
        overlaySocket = OverlaySocketManager(
            backendUrl = backendUrl,
            onStatus = { status ->
                currentAssistantBubbleId?.let { updateMessage(it, status) }
            },
            onChunk = { _, full ->
                currentAssistantBubbleId?.let { updateMessage(it, full) }
            },
            onDone = { full ->
                val lastUser = getLastUserMessage() ?: ""
                if (lastUser.isNotEmpty() && full.isNotEmpty()) {
                    OverlayMemory.appendTurn(this, lastUser, full)
                }
                currentAssistantBubbleId = null
                isSending = false
                sendBtn?.isEnabled = true
            },
            onError = { msg ->
                currentAssistantBubbleId?.let { updateMessage(it, msg) }
                currentAssistantBubbleId = null
                isSending = false
                sendBtn?.isEnabled = true
            },
            onContextDetected = { detectedItems, suggestions ->
                renderContextDetected(detectedItems, suggestions)
            }
        )
    }

    private var lastUserQuery = ""

    private fun getLastUserMessage(): String? = lastUserQuery.ifEmpty { null }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra("backend_url")?.let {
            if (it.isNotEmpty()) {
                backendUrl = it
                overlaySocket?.updateBackendUrl(it)
                Log.d(TAG, "Backend URL configured: $backendUrl")
            }
        }
        intent?.getStringExtra("assistant_mode")?.let { mode ->
            if (mode.isNotEmpty()) assistantMode = mode
        }

        if (intent?.action == "ACTION_START_PROJECTION") {
            val resultCode = intent.getIntExtra("result_code", 0)
            @Suppress("DEPRECATION")
            val dataIntent = intent.getParcelableExtra<Intent>("data_intent")
            if (resultCode != 0 && dataIntent != null) {
                // Must configure foreground service type to include mediaProjection BEFORE invoking getMediaProjection() on SDK 34+
                hasActiveProjection = true
                upgradeToProjectionForeground()
                setupMediaProjection(resultCode, dataIntent)
            }
        }

        showBubble()
        return START_STICKY
    }

    private fun setupNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AURA System Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Runs the system-wide floating overlay assistant"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        startForegroundWithTypes(buildNotification(), includeMediaProjection = hasActiveProjection)
    }

    /** Never claim mediaProjection FGS type until a MediaProjection token exists. */
    private fun startForegroundWithTypes(notification: android.app.Notification, includeMediaProjection: Boolean) {
        try {
            if (Build.VERSION.SDK_INT >= 34) { // Android 14+ requires specialUse/mediaProjection foreground service types
                val fgsType = if (includeMediaProjection) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                }
                startForeground(NOTIFICATION_ID, notification, fgsType)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { // Android 10-13 (API 29-33)
                if (includeMediaProjection) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed (types=$includeMediaProjection): ${e.message}")
            throw e
        }
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("AURA System Assistant")
        .setContentText("AURA Overlay is active system-wide.")
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    private fun upgradeToProjectionForeground() {
        if (!hasActiveProjection) {
            Log.w(TAG, "Skipping projection foreground upgrade — no active MediaProjection")
            return
        }
        try {
            startForegroundWithTypes(buildNotification(), includeMediaProjection = true)
            Log.d(TAG, "Upgraded foreground service to include mediaProjection type")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upgrade foreground type: ${e.message}")
        }
    }

    private fun setupMediaProjection(resultCode: Int, dataIntent: Intent) {
        try {
            val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = mpManager.getMediaProjection(resultCode, dataIntent)
            hasActiveProjection = true
            Log.d(TAG, "MediaProjection successfully configured in Foreground Service.")
        } catch (e: Exception) {
            hasActiveProjection = false
            Log.e(TAG, "Failed to start MediaProjection: ${e.message}")
        }
    }

    private fun startScreenCapture(onDone: () -> Unit) {
        val mp = mediaProjection
        if (mp == null) {
            Log.w(TAG, "MediaProjection not active. Cannot capture screenshot.")
            onDone()
            return
        }

        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        val width = displayMetrics.widthPixels
        val height = displayMetrics.heightPixels
        val density = displayMetrics.densityDpi

        try {
            val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            val flags = DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR
            val vd = mp.createVirtualDisplay(
                "AURA_SCREENSHOT",
                width, height, density,
                flags,
                reader.surface,
                null, null
            )

            reader.setOnImageAvailableListener({ r ->
                var image: Image? = null
                try {
                    image = r.acquireLatestImage()
                    if (image != null) {
                        val planes = image.planes
                        val buffer = planes[0].buffer
                        val pixelStride = planes[0].pixelStride
                        val rowStride = planes[0].rowStride
                        val rowPadding = rowStride - pixelStride * width

                        val bitmap = Bitmap.createBitmap(
                            width + rowPadding / pixelStride,
                            height,
                            Bitmap.Config.ARGB_8888
                        )
                        bitmap.copyPixelsFromBuffer(buffer)

                        val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height)
                        val outputStream = ByteArrayOutputStream()
                        croppedBitmap.compress(Bitmap.CompressFormat.JPEG, 70, outputStream)
                        val bytes = outputStream.toByteArray()
                        val base64Image = Base64.encodeToString(bytes, Base64.NO_WRAP)
                        
                        lastCapturedScreenshotBase64 = "data:image/jpeg;base64,$base64Image"
                        Log.d(TAG, "Screen captured successfully.")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in screenshot image processing: ${e.message}")
                } finally {
                    image?.close()
                    vd?.release()
                    r.close()
                    onDone()
                }
            }, null)
        } catch (e: Exception) {
            Log.e(TAG, "Error during media projection screen capture: ${e.message}")
            onDone()
        }
    }

    private fun setupFloatingLayouts() {
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val density = resources.displayMetrics.density
        val bubbleSize = (64 * density).toInt()
        val coreSize = (32 * density).toInt()

        // 1. SETUP BUBBLE VIEW
        val bubbleFrame = FrameLayout(this)
        bubbleFrame.setBackgroundResource(R.drawable.aura_bubble_bg)
        
        // Inner glowing core
        val coreImage = ImageView(this).apply {
            id = CORE_IMAGE_ID
            setImageResource(android.R.drawable.ic_btn_speak_now)
            setColorFilter(Color.parseColor("#00f2ff"))
        }
        val coreParams = FrameLayout.LayoutParams(coreSize, coreSize, Gravity.CENTER)
        bubbleFrame.addView(coreImage, coreParams)
        bubbleView = bubbleFrame

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        bubbleParams = WindowManager.LayoutParams(
            bubbleSize, bubbleSize,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenWidth - bubbleSize - (16 * density).toInt()
            y = screenHeight / 4
        }

        // Draggable listener for the bubble
        bubbleView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0.0f
            private var initialTouchY = 0.0f
            private var clickThreshold = 10
            private var isMoving = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = bubbleParams!!.x
                        initialY = bubbleParams!!.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        isMoving = false
                        stopBubblePulseAnimation()
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        if (Math.abs(dx) > clickThreshold || Math.abs(dy) > clickThreshold) {
                            isMoving = true
                        }
                        bubbleParams!!.x = initialX + dx
                        bubbleParams!!.y = initialY + dy
                        if (bubbleView?.parent != null) {
                            windowManager.updateViewLayout(bubbleView, bubbleParams)
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!isMoving) {
                            // Tap event - open chat panel
                            expandToChat()
                        } else {
                            // Snap to edge (Magnetic edges)
                            val centerX = bubbleParams!!.x + bubbleSize / 2
                            val destinationX = if (centerX < screenWidth / 2) {
                                (16 * density).toInt()
                            } else {
                                screenWidth - bubbleSize - (16 * density).toInt()
                            }
                            
                            val animator = ValueAnimator.ofInt(bubbleParams!!.x, destinationX).apply {
                                duration = 250
                                addUpdateListener { animation ->
                                    bubbleParams!!.x = animation.animatedValue as Int
                                    if (bubbleView?.parent != null) {
                                        windowManager.updateViewLayout(bubbleView, bubbleParams)
                                    }
                                }
                            }
                            animator.start()
                            startBubblePulseAnimation()
                        }
                        return true
                    }
                }
                return false
            }
        })

        // 2. SETUP EXPANDED CHAT VIEW
        val mainChatLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundResource(R.drawable.aura_panel_bg)
            val padVal = (16 * resources.displayMetrics.density).toInt()
            setPadding(padVal, padVal, padVal, padVal)
        }

        // Header Row
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            params.setMargins(0, 0, 0, 16)
            layoutParams = params
        }

        val headerDot = View(this).apply {
            val gd = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#06B6D4"))
            }
            background = gd
            val params = LinearLayout.LayoutParams(16, 16)
            params.setMargins(0, 0, 16, 0)
            layoutParams = params
        }
        header.addView(headerDot)

        val modeBtn = Button(this).apply {
            text = assistantMode.uppercase().take(5)
            setBackgroundResource(R.drawable.aura_button_bg)
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 9f
            setOnClickListener { cycleAssistantMode() }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 8, 0) }
        }
        header.addView(modeBtn)

        val headerTitle = TextView(this).apply {
            text = "AURA OVERLAY"
            setTextColor(Color.parseColor("#06B6D4"))
            textSize = 12f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            letterSpacing = 0.15f
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f)
        }
        header.addView(headerTitle)

        // Minimize icon
        val minimizeBtn = TextView(this).apply {
            text = "━"
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(12, 12, 12, 12)
            setOnClickListener { minimizeChat() }
        }
        header.addView(minimizeBtn)

        // Close-all icon
        val closeAllBtn = TextView(this).apply {
            text = "✕"
            setTextColor(Color.WHITE)
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(12, 12, 12, 12)
            setOnClickListener { stopSelf() }
        }
        header.addView(closeAllBtn)

        mainChatLayout.addView(header)

        // Message board ScrollView
        chatScrollView = ScrollView(this).apply {
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f
            )
            params.setMargins(0, 0, 0, 12)
            layoutParams = params
        }
        messageContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        chatScrollView.addView(messageContainer)
        mainChatLayout.addView(chatScrollView)

        // Bottom input row
        val inputRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Screen Analyze context button
        val analyzeBtn = Button(this).apply {
            text = "SCAN"
            setBackgroundResource(R.drawable.aura_button_bg)
            setTextColor(Color.parseColor("#00f2ff"))
            textSize = 11f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                100
            ).apply {
                setMargins(0, 0, 12, 0)
            }
            setOnClickListener {
                val activeApp = AuraAccessibilityService.getActiveAppName()
                val activePkg = AuraAccessibilityService.getActiveAppPackage()
                appendMessage("system", "Scanning screen context on $activeApp...")
                
                startScreenCapture {
                    val screenText = AuraAccessibilityService.getLastCapturedScreenText()
                    val payload = JSONObject().apply {
                        put("event", "analyze")
                        put("type", "analyze")
                        put("active_app", activePkg.ifEmpty { activeApp })
                        put("window_title", activeApp)
                        put("accessibility_text", screenText.take(4000))
                        lastCapturedScreenshotBase64?.let { put("screenshot", it) }
                    }
                    lastCapturedScreenshotBase64 = null
                    
                    val socket = overlaySocket
                    if (socket != null) {
                        try {
                            socket.send(payload)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to send analyze payload: ${e.message}")
                            messageContainer.post {
                                appendMessage("system", "Scan connection failed. Check backend connection.")
                            }
                        }
                    } else {
                        messageContainer.post {
                            appendMessage("system", "Scan failed: Connection not ready.")
                        }
                    }
                }
            }
        }
        inputRow.addView(analyzeBtn)

        inputField = EditText(this).apply {
            hint = "Ask AURA anything..."
            setHintTextColor(Color.parseColor("#55FFFFFF"))
            setTextColor(Color.WHITE)
            textSize = 13f
            setBackgroundColor(Color.TRANSPARENT)
            val params = LinearLayout.LayoutParams(0, 120, 1.0f)
            params.setMargins(0, 0, 12, 0)
            layoutParams = params
        }
        inputRow.addView(inputField)

        sendBtn = Button(this).apply {
            text = "SEND"
            setBackgroundResource(R.drawable.aura_button_bg)
            setTextColor(Color.parseColor("#06B6D4"))
            textSize = 11f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                100
            )
            setOnClickListener { onSendClicked() }
        }
        inputRow.addView(sendBtn)

        inputField.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == android.view.inputmethod.EditorInfo.IME_ACTION_SEND) {
                onSendClicked()
                true
            } else false
        }

        mainChatLayout.addView(inputRow)
        chatView = mainChatLayout

        chatParams = WindowManager.LayoutParams(
            (screenWidth * 0.85).toInt(), (screenHeight * 0.45).toInt(),
            overlayType,
            WindowManager.LayoutParams.FLAG_DIM_BEHIND or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            dimAmount = 0.3f
            gravity = Gravity.CENTER
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        }
    }

    private fun showBubble() {
        try {
            if (bubbleView?.parent == null) {
                windowManager.addView(bubbleView, bubbleParams)
                startBubblePulseAnimation()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing bubble: ${e.message}")
        }
    }

    private fun startBubblePulseAnimation() {
        if (bubblePulseAnimator != null) return
        val coreImage = bubbleView?.findViewById<ImageView>(CORE_IMAGE_ID) ?: return
        bubblePulseAnimator = ValueAnimator.ofFloat(0.9f, 1.1f).apply {
            duration = 1500
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener { animation ->
                val scale = animation.animatedValue as Float
                coreImage.scaleX = scale
                coreImage.scaleY = scale
            }
        }
        bubblePulseAnimator?.start()
    }

    private fun stopBubblePulseAnimation() {
        bubblePulseAnimator?.cancel()
        bubblePulseAnimator = null
    }

    private fun expandToChat() {
        try {
            stopBubblePulseAnimation()
            if (bubbleView?.parent != null) {
                windowManager.removeView(bubbleView)
            }
            if (chatView?.parent == null) {
                windowManager.addView(chatView, chatParams)
                if (messageContainer.childCount == 0) {
                    appendMessage("assistant", "How can I assist you in your current workflow today?")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error expanding chat: ${e.message}")
        }
    }

    private fun cycleAssistantMode() {
        val modes = arrayOf("quick", "tutor", "copilot", "focus", "research")
        val idx = modes.indexOf(assistantMode)
        assistantMode = modes[(idx + 1) % modes.size]
        getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString("overlay_assistant_mode", assistantMode)
            .apply()
        appendMessage("system", "Mode: ${assistantMode.replaceFirstChar { it.uppercase() }}")
    }

    private fun minimizeChat() {
        try {
            if (chatView?.parent != null) {
                windowManager.removeView(chatView)
            }
            showBubble()
        } catch (e: Exception) {
            Log.e(TAG, "Error minimizing chat: ${e.message}")
        }
    }

    private fun onSendClicked() {
        val now = System.currentTimeMillis()
        if (now - lastSendClickMs < 400) return
        lastSendClickMs = now
        sendMessage()
    }

    private fun sendMessageViaHttp(payload: JSONObject) {
        val payloadStr = payload.toString()
        Thread {
            try {
                val mediaType = "application/json; charset=utf-8".toMediaTypeOrNull()
                val body = payloadStr.toRequestBody(mediaType)
                val request = Request.Builder()
                    .url("$backendUrl/overlay/chat")
                    .post(body)
                    .build()
                val response = httpClient.newCall(request).execute()
                val responseText = response.body?.string() ?: ""
                Handler(Looper.getMainLooper()).post {
                    if (response.isSuccessful && responseText.isNotEmpty()) {
                        try {
                            val obj = org.json.JSONObject(responseText)
                            val reply = obj.optString("response", responseText)
                            currentAssistantBubbleId?.let { updateMessage(it, reply) }
                            OverlayMemory.appendTurn(this, lastUserQuery, reply)
                        } catch (e: Exception) {
                            currentAssistantBubbleId?.let { updateMessage(it, responseText) }
                        }
                    } else {
                        currentAssistantBubbleId?.let {
                            updateMessage(it, "AURA overlay lost connection. Retrying…")
                        }
                    }
                    isSending = false
                    sendBtn?.isEnabled = true
                    currentAssistantBubbleId = null
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    currentAssistantBubbleId?.let {
                        updateMessage(it, "Cannot reach AURA. Check network or backend URL.")
                    }
                    isSending = false
                    sendBtn?.isEnabled = true
                    currentAssistantBubbleId = null
                }
            }
        }.start()
    }

    private fun sendMessage() {
        if (isSending) return
        val query = inputField.text.toString().trim()
        if (query.isEmpty()) return

        isSending = true
        sendBtn?.isEnabled = false
        lastUserQuery = query
        inputField.text.clear()

        appendMessage("user", query)

        val screenText = AuraAccessibilityService.getLastCapturedScreenText()
        val activeAppName = AuraAccessibilityService.getActiveAppName()
        val activePkg = AuraAccessibilityService.getActiveAppPackage()

        val sandboxObj = JSONObject().apply {
            put("platform", "android")
            put("overlay_mode", true)
            put("assistant_mode", assistantMode)
            put("ocr", true)
            put("accessibility_text", screenText.take(4000))
            put("active_app", activePkg.ifEmpty { activeAppName })
            put("window_title", activeAppName)
            put("persona", "warm-narrative")
            put("search_strategy", if (assistantMode == "research") "multi-tier" else "local-only")
            lastCapturedScreenshotBase64?.let { put("screenshot", it) }
        }
        lastCapturedScreenshotBase64 = null

        val history = OverlayMemory.load(this)
        val payload = JSONObject().apply {
            put("prompt", query)
            put("conversationId", OverlaySocketManager.CONVERSATION_ID)
            put("projectId", "overlay")
            put("history", history)
            put("sandbox", sandboxObj)
        }

        currentAssistantBubbleId = appendMessage("assistant", "…")

        val socket = overlaySocket
        if (socket == null) {
            sendMessageViaHttp(payload)
            return
        }
        try {
            socket.send(payload)
        } catch (e: Exception) {
            Log.e(TAG, "Overlay send failed: ${e.message}")
            sendMessageViaHttp(payload)
        }
    }

    private fun appendMessage(sender: String, messageText: String): Int {
        val bubbleId = View.generateViewId()
        
        messageContainer.post {
            val messageRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = if (sender == "user") Gravity.END else Gravity.START
                val params = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                params.setMargins(0, 8, 0, 8)
                layoutParams = params
            }

            val bubbleBg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 16f
                if (sender == "user") {
                    setColor(Color.parseColor("#1F2937"))
                    setStroke(1, Color.parseColor("#374151"))
                } else if (sender == "system") {
                    setColor(Color.parseColor("#991B1B"))
                } else {
                    setColor(Color.parseColor("#1E293B"))
                    setStroke(1, Color.parseColor("#06B6D4"))
                }
            }

            val messageView = TextView(this).apply {
                id = bubbleId
                text = messageText
                setTextColor(Color.WHITE)
                textSize = 12f
                setPadding(16, 12, 16, 12)
                background = bubbleBg
                maxWidth = (resources.displayMetrics.widthPixels * 0.65).toInt()
            }
            messageRow.addView(messageView)
            messageContainer.addView(messageRow)

            chatScrollView.post {
                chatScrollView.fullScroll(View.FOCUS_DOWN)
            }
        }

        return bubbleId
    }

    private fun updateMessage(viewId: Int, newText: String) {
        messageContainer.post {
            val textView = messageContainer.findViewById<TextView>(viewId)
            textView?.text = newText
            chatScrollView.post {
                chatScrollView.fullScroll(View.FOCUS_DOWN)
            }
        }
    }

    private fun renderContextDetected(detectedItems: List<String>, suggestions: List<Pair<String, String>>) {
        messageContainer.post {
            if (detectedItems.isNotEmpty()) {
                val scroll = android.widget.HorizontalScrollView(this).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply { setMargins(0, 8, 0, 8) }
                }
                val scrollContent = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                }
                
                for (item in detectedItems) {
                    val tagView = TextView(this).apply {
                        text = item
                        setTextColor(Color.parseColor("#00f2ff"))
                        textSize = 10f
                        setPadding(12, 6, 12, 6)
                        val gd = GradientDrawable().apply {
                            shape = GradientDrawable.RECTANGLE
                            cornerRadius = 24f
                            setColor(Color.parseColor("#0F172A"))
                            setStroke(1, Color.parseColor("#06B6D4"))
                        }
                        background = gd
                        layoutParams = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.WRAP_CONTENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        ).apply { setMargins(0, 0, 8, 0) }
                    }
                    scrollContent.addView(tagView)
                }
                scroll.addView(scrollContent)
                messageContainer.addView(scroll)
            }
            
            if (suggestions.isNotEmpty()) {
                val suggestionsLayout = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply { setMargins(0, 8, 0, 8) }
                }
                
                for (suggestion in suggestions) {
                    val label = suggestion.first
                    val prompt = suggestion.second
                    val chipBtn = Button(this).apply {
                        text = label
                        transformationMethod = null
                        setBackgroundResource(R.drawable.aura_button_bg)
                        setTextColor(Color.WHITE)
                        textSize = 11f
                        setPadding(16, 12, 16, 12)
                        layoutParams = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.MATCH_PARENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        ).apply { setMargins(0, 4, 0, 4) }
                        
                        setOnClickListener {
                            inputField.setText(prompt)
                            onSendClicked()
                        }
                    }
                    suggestionsLayout.addView(chipBtn)
                }
                messageContainer.addView(suggestionsLayout)
            }
            
            chatScrollView.post {
                chatScrollView.fullScroll(View.FOCUS_DOWN)
            }
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "AURA Overlay Service Destroyed")
        overlaySocket?.disconnect()
        stopBubblePulseAnimation()
        
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            Log.d(TAG, "WakeLock released successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
        
        try {
            mediaProjection?.stop()
            mediaProjection = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaProjection: ${e.message}")
        }

        try {
            if (bubbleView?.parent != null) {
                windowManager.removeView(bubbleView)
            }
            if (chatView?.parent != null) {
                windowManager.removeView(chatView)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing view on destroy: ${e.message}")
        }
        super.onDestroy()
    }
}
