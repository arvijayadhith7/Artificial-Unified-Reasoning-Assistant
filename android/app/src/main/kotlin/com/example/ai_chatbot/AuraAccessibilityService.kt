package com.example.ai_chatbot

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AuraAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AURA_ACCESSIBILITY"
        private var lastCapturedText = ""
        private var activeAppPackage = ""
        private var activeAppName = "Home Screen"

        fun getLastCapturedScreenText(): String {
            return lastCapturedText
        }

        fun getActiveAppPackage(): String {
            return activeAppPackage
        }

        fun getActiveAppName(): String {
            return activeAppName
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Update active package & app name
        event.packageName?.toString()?.let { pkg ->
            if (pkg != activeAppPackage) {
                activeAppPackage = pkg
                activeAppName = try {
                    val pm = packageManager
                    val appInfo = pm.getApplicationInfo(pkg, 0)
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    pkg
                }
                Log.d(TAG, "Active App: $activeAppName ($activeAppPackage)")
            }
        }
        
        val source = event.source
        if (source != null) {
            val sb = StringBuilder()
            extractText(source, sb)
            val text = sb.toString().trim()
            if (text.isNotEmpty() && text.length > 5) {
                lastCapturedText = text
            }
        }
    }

    private fun extractText(node: AccessibilityNodeInfo, sb: StringBuilder) {
        val text = node.text
        if (text != null && text.toString().trim().isNotEmpty()) {
            sb.append(text).append("\n")
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                extractText(child, sb)
                child.recycle()
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Aura Accessibility Service Interrupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Aura Accessibility Service Connected")
    }
}
