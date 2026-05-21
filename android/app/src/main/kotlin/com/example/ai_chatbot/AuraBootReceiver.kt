package com.example.ai_chatbot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AuraBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("AURA_BOOT", "Reboot detected, checking overlay preference...")
            
            val prefs = context.getSharedPreferences("aura_prefs", Context.MODE_PRIVATE)
            val backendUrl = prefs.getString("backend_url", "https://vijayadhith7-aura-backend.hf.space") ?: "https://vijayadhith7-aura-backend.hf.space"

            // Only start on boot if the user previously enabled overlay (synced from Flutter)
            var overlayEnabled = prefs.getBoolean("overlay_enabled", false)
            if (!overlayEnabled) {
                val cachedSettings = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.aura_cached_settings", null)
                overlayEnabled = cachedSettings?.contains("\"overlayEnabled\":true") == true
            }

            if (!overlayEnabled) {
                Log.d("AURA_BOOT", "Overlay not enabled by user, skipping service start.")
                return
            }
            
            Log.d("AURA_BOOT", "Overlay was enabled, launching AURA Overlay Service...")
            val serviceIntent = Intent(context, AuraForegroundService::class.java).apply {
                putExtra("backend_url", backendUrl)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                Log.e("AURA_BOOT", "Failed to start service on boot: ${e.message}")
            }
        }
    }
}
