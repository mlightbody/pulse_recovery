package com.malcolmlightbody.pulserecovery

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "pulse_recovery/watch_sessions"

        private const val PREFS_NAME = "watch_sessions"
        private const val RECEIVED_SESSIONS_KEY = "received_sessions"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getReceivedWatchSessions" -> {
                    val sessionsJson = getReceivedWatchSessionsJson()
                    result.success(sessionsJson)
                }

                "clearReceivedWatchSessions" -> {
                    clearReceivedWatchSessions()
                    result.success(true)
                }

                "markWatchSessionImported" -> {
                    val sessionId = call.argument<String>("sessionId")

                    if (sessionId.isNullOrBlank()) {
                        result.error(
                            "missing_session_id",
                            "sessionId was missing",
                            null
                        )
                    } else {
                        markWatchSessionImported(sessionId)
                        result.success(true)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getReceivedWatchSessionsJson(): String {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        return prefs.getString(RECEIVED_SESSIONS_KEY, "[]") ?: "[]"
    }

    private fun clearReceivedWatchSessions() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        prefs.edit()
            .remove(RECEIVED_SESSIONS_KEY)
            .apply()
    }

    private fun markWatchSessionImported(sessionId: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(RECEIVED_SESSIONS_KEY, "[]") ?: "[]"

        val updated = try {
            val array = org.json.JSONArray(existing)
            val newArray = org.json.JSONArray()

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)

                if (obj.optString("sessionId") == sessionId) {
                    obj.put("importStatus", "imported")
                    obj.put("importedAtMillis", System.currentTimeMillis())
                }

                newArray.put(obj)
            }

            newArray.toString()
        } catch (e: Exception) {
            existing
        }

        prefs.edit()
            .putString(RECEIVED_SESSIONS_KEY, updated)
            .apply()
    }
}