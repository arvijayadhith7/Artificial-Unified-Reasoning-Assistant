package com.example.ai_chatbot

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_chatbot/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "startOverlayService" -> {
                    val backendUrl = call.argument<String>("backend_url") ?: "http://10.0.2.2:7860"
                    startOverlayService(backendUrl)
                    result.success(true)
                }
                "stopOverlayService" -> {
                    stopOverlayService()
                    result.success(true)
                }
                "setOverlayEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("overlay_enabled", enabled)
                        .apply()
                    result.success(true)
                }
                "checkBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                "checkScreenCapturePermission" -> {
                    result.success(hasScreenCapturePermission)
                }
                "requestScreenCapturePermission" -> {
                    screenCaptureResultChannel = result
                    val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as android.media.projection.MediaProjectionManager
                    startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), SCREEN_CAPTURE_REQUEST_CODE)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private val SCREEN_CAPTURE_REQUEST_CODE = 2002
    private var screenCaptureResultChannel: MethodChannel.Result? = null
    private var hasScreenCapturePermission = false

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                hasScreenCapturePermission = true
                
                // Propagate the projection token intent to the foreground service
                val serviceIntent = Intent(this, AuraForegroundService::class.java).apply {
                    action = "ACTION_START_PROJECTION"
                    putExtra("result_code", resultCode)
                    putExtra("data_intent", data)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                
                screenCaptureResultChannel?.success(true)
            } else {
                hasScreenCapturePermission = false
                screenCaptureResultChannel?.success(false)
            }
            screenCaptureResultChannel = null
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = ComponentName(this, AuraAccessibilityService::class.java)
        val enabledServicesSetting = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)
        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledService = ComponentName.unflattenFromString(componentNameString)
            if (enabledService != null && enabledService == expectedComponentName) {
                return true
            }
        }
        return false
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }

    private fun startOverlayService(backendUrl: String) {
        val prefs = getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("backend_url", backendUrl)
            .putBoolean("overlay_enabled", true)
            .apply()

        val mode = getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
            .getString("overlay_assistant_mode", "quick") ?: "quick"
        val intent = Intent(this, AuraForegroundService::class.java).apply {
            putExtra("backend_url", backendUrl)
            putExtra("assistant_mode", mode)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to start overlay service: ${e.message}")
            throw e
        }
    }

    private fun stopOverlayService() {
        getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("overlay_enabled", false)
            .apply()
        val intent = Intent(this, AuraForegroundService::class.java)
        stopService(intent)
    }
}
