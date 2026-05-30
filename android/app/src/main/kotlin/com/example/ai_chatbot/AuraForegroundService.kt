package com.example.ai_chatbot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
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
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.ByteArrayOutputStream

class AuraForegroundService : Service() {

    private lateinit var windowManager: WindowManager
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    private var wakeLock: PowerManager.WakeLock? = null
    private var mediaProjection: MediaProjection? = null
    private var hasActiveProjection = false
    private var lastCapturedScreenshotBase64: String? = null

    companion object {
        private const val TAG = "AURA_SERVICE"
        private const val CHANNEL_ID = "aura_overlay_channel"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AURA Overlay Service Created")
        
        // 1. Acquire WakeLock
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

        try {
            setupNotification()
            initFlutterEngine()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup overlay: ${e.message}")
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "ACTION_START_PROJECTION") {
            val resultCode = intent.getIntExtra("result_code", 0)
            @Suppress("DEPRECATION")
            val dataIntent = intent.getParcelableExtra<Intent>("data_intent")
            if (resultCode != 0 && dataIntent != null) {
                hasActiveProjection = true
                upgradeToProjectionForeground()
                setupMediaProjection(resultCode, dataIntent)
            }
        }
        return START_STICKY
    }

    private fun initFlutterEngine() {
        Log.d(TAG, "Initializing background FlutterEngine for Overlay")
        val context = applicationContext
        
        // Create FlutterEngine and register plugins
        flutterEngine = FlutterEngine(context).apply {
            GeneratedPluginRegistrant.registerWith(this)
        }

        // Initialize Loader and execute entrypoint
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(context)
        }
        loader.ensureInitializationComplete(context, null)
        val bundlePath = loader.findAppBundlePath()
        
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(bundlePath, "overlayMain")
        )

        // Attach to FlutterView
        flutterView = FlutterView(context, FlutterTextureView(context))
        flutterView?.attachToFlutterEngine(flutterEngine!!)

        // Setup WindowManager Layout Params
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val density = resources.displayMetrics.density
        // Starts as compact Bubble size (52x52 for cute, non-intrusive feel)
        val size = (52 * density).toInt()

        layoutParams = WindowManager.LayoutParams(
            size, size,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - size - (8 * density).toInt()
            y = resources.displayMetrics.heightPixels / 3
        }

        windowManager.addView(flutterView, layoutParams)
        
        // Notify Dart lifecycle resumed
        flutterEngine?.lifecycleChannel?.appIsResumed()

        setupMethodChannel()
    }

    private fun setupMethodChannel() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return
        MethodChannel(messenger, "com.example.ai_chatbot/overlay_runtime").setMethodCallHandler { call, result ->
            when (call.method) {
                "resize" -> {
                    val widthDp = call.argument<Double>("width") ?: 72.0
                    val heightDp = call.argument<Double>("height") ?: 72.0
                    val density = resources.displayMetrics.density
                    layoutParams?.width = (widthDp * density).toInt()
                    layoutParams?.height = (heightDp * density).toInt()
                    windowManager.updateViewLayout(flutterView, layoutParams)
                    result.success(true)
                }
                "setFocusable" -> {
                    val focusable = call.argument<Boolean>("focusable") ?: false
                    var flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    if (!focusable) {
                        flags = flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    }
                    layoutParams?.flags = flags
                    windowManager.updateViewLayout(flutterView, layoutParams)
                    result.success(true)
                }
                "updatePosition" -> {
                    val dxDp = call.argument<Double>("dx") ?: 0.0
                    val dyDp = call.argument<Double>("dy") ?: 0.0
                    val density = resources.displayMetrics.density
                    layoutParams?.x = (layoutParams?.x ?: 0) + (dxDp * density).toInt()
                    layoutParams?.y = (layoutParams?.y ?: 0) + (dyDp * density).toInt()
                    windowManager.updateViewLayout(flutterView, layoutParams)
                    result.success(true)
                }
                "setPosition" -> {
                    val xDp = call.argument<Double>("x")
                    val yDp = call.argument<Double>("y")
                    val density = resources.displayMetrics.density
                    if (xDp != null && yDp != null) {
                        layoutParams?.x = (xDp * density).toInt()
                        layoutParams?.y = (yDp * density).toInt()
                        windowManager.updateViewLayout(flutterView, layoutParams)
                    }
                    result.success(true)
                }
                "getScreenContext" -> {
                    val text = AuraAccessibilityService.getLastCapturedScreenText()
                    val pkg = AuraAccessibilityService.getActiveAppPackage()
                    val name = AuraAccessibilityService.getActiveAppName()
                    result.success(mapOf(
                        "text" to text,
                        "package" to pkg,
                        "name" to name
                    ))
                }
                "captureScreenshot" -> {
                    startScreenCapture {
                        result.success(lastCapturedScreenshotBase64)
                        lastCapturedScreenshotBase64 = null
                    }
                }
                "close" -> {
                    stopSelf()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
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

    private fun startForegroundWithTypes(notification: android.app.Notification, includeMediaProjection: Boolean) {
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                val fgsType = if (includeMediaProjection) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                } else {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                }
                startForeground(NOTIFICATION_ID, notification, fgsType)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (includeMediaProjection) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed: ${e.message}")
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
        if (!hasActiveProjection) return
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

    override fun onDestroy() {
        Log.d(TAG, "AURA Overlay Service Destroyed")
        
        try {
            if (flutterView != null && flutterView?.parent != null) {
                windowManager.removeView(flutterView)
            }
            flutterView?.detachFromFlutterEngine()
            flutterView = null
        } catch (e: Exception) {
            Log.e(TAG, "Error removing view on destroy: ${e.message}")
        }

        try {
            flutterEngine?.destroy()
            flutterEngine = null
        } catch (e: Exception) {
            Log.e(TAG, "Error destroying FlutterEngine: ${e.message}")
        }

        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
        
        try {
            mediaProjection?.stop()
            mediaProjection = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaProjection: ${e.message}")
        }

        super.onDestroy()
    }
}
