package com.example.ai_chatbot

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Isolated overlay conversation memory — never mixed with main app chat.
 */
object OverlayMemory {
    private const val PREFS = "aura_overlay_memory"
    private const val KEY_HISTORY = "history_json"
    private const val MAX_TURNS = 8

    fun load(context: Context): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_HISTORY, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    fun save(context: Context, history: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_HISTORY, history.toString())
            .apply()
    }

    fun appendTurn(context: Context, user: String, assistant: String) {
        val history = load(context)
        history.put(JSONObject().apply {
            put("role", "user")
            put("content", user)
        })
        history.put(JSONObject().apply {
            put("role", "assistant")
            put("content", assistant)
        })
        while (history.length() > MAX_TURNS * 2) {
            history.remove(0)
        }
        save(context, history)
    }

    fun clear(context: Context) {
        save(context, JSONArray())
    }
}
