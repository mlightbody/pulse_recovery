package com.malcolmlightbody.pulserecovery.wear

import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONArray
import org.json.JSONObject
import java.nio.charset.StandardCharsets

class WearSessionReceiverService : WearableListenerService() {

    companion object {
        private const val TAG = "WearSessionReceiver"
        private const val HR_SESSION_PATH_PREFIX = "/hr_session"
        private const val HR_SESSION_ACK_PATH = "/hr_session_ack"

        private const val PREFS_NAME = "watch_sessions"
        private const val RECEIVED_SESSIONS_KEY = "received_sessions"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)

        dataEvents.forEach { event ->
            if (event.type != DataEvent.TYPE_CHANGED) {
                return@forEach
            }

            val dataItem = event.dataItem
            val path = dataItem.uri.path ?: return@forEach

            if (!path.startsWith(HR_SESSION_PATH_PREFIX)) {
                return@forEach
            }

            try {
                val dataMap = DataMapItem.fromDataItem(dataItem).dataMap

                val sessionId = dataMap.getString("sessionId") ?: "unknown"
                val source = dataMap.getString("source") ?: "galaxy_watch"
                val payload = dataMap.getString("payload")

                if (payload.isNullOrBlank()) {
                    Log.w(TAG, "Received HR session $sessionId but payload was empty")
                    return@forEach
                }

                val payloadJson = JSONObject(payload)
                val points = payloadJson.optJSONArray("points") ?: JSONArray()

                val schemaVersion = payloadJson.optInt(
                    "schemaVersion",
                    dataMap.getInt("schemaVersion", 1)
                )

                val workoutStartedAtMillis = payloadJson.optLong(
                    "workoutStartedAtMillis",
                    payloadJson.optLong("startedAtMillis", 0L)
                )

                val workoutEndedAtMillis = nullableLong(payloadJson, "workoutEndedAtMillis")
                    ?: nullableLong(payloadJson, "endedAtMillis")

                val recoveryEndedAtMillis = nullableLong(payloadJson, "recoveryEndedAtMillis")

                val peakHr = nullableDouble(payloadJson, "peakHr")
                val workoutEndHr = nullableDouble(payloadJson, "workoutEndHr")
                val hr60 = nullableDouble(payloadJson, "hr60")
                val hr120 = nullableDouble(payloadJson, "hr120")

                val sampleCount = points.length()
                val maxHr = calculateMaxHr(points)
                val durationSeconds = calculateDurationSeconds(
                    workoutStartedAtMillis,
                    recoveryEndedAtMillis ?: workoutEndedAtMillis
                )

                Log.i(TAG, "Received HR session")
                Log.i(TAG, "Session ID: $sessionId")
                Log.i(TAG, "Schema version: $schemaVersion")
                Log.i(TAG, "Source: $source")
                Log.i(TAG, "Workout started: $workoutStartedAtMillis")
                Log.i(TAG, "Workout ended: $workoutEndedAtMillis")
                Log.i(TAG, "Recovery ended: $recoveryEndedAtMillis")
                Log.i(TAG, "Peak HR: $peakHr")
                Log.i(TAG, "Workout end HR: $workoutEndHr")
                Log.i(TAG, "HR60: $hr60")
                Log.i(TAG, "HR120: $hr120")
                Log.i(TAG, "Samples: $sampleCount")

                saveReceivedSession(
                    sessionId = sessionId,
                    source = source,
                    schemaVersion = schemaVersion,
                    workoutStartedAtMillis = workoutStartedAtMillis,
                    workoutEndedAtMillis = workoutEndedAtMillis,
                    recoveryEndedAtMillis = recoveryEndedAtMillis,
                    receivedAtMillis = System.currentTimeMillis(),
                    peakHr = peakHr,
                    workoutEndHr = workoutEndHr,
                    hr60 = hr60,
                    hr120 = hr120,
                    sampleCount = sampleCount,
                    maxHr = maxHr,
                    durationSeconds = durationSeconds,
                    payload = payload
                )

                sendAckToWatch(
                    sourceNodeId = dataItem.uri.host,
                    sessionId = sessionId
                )

            } catch (e: Exception) {
                Log.e(TAG, "Failed to process HR session", e)
            }
        }
    }

    private fun saveReceivedSession(
        sessionId: String,
        source: String,
        schemaVersion: Int,
        workoutStartedAtMillis: Long,
        workoutEndedAtMillis: Long?,
        recoveryEndedAtMillis: Long?,
        receivedAtMillis: Long,
        peakHr: Double?,
        workoutEndHr: Double?,
        hr60: Double?,
        hr120: Double?,
        sampleCount: Int,
        maxHr: Int,
        durationSeconds: Int,
        payload: String
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val existingString = prefs.getString(RECEIVED_SESSIONS_KEY, null)

        val existingSessions = if (existingString.isNullOrBlank()) {
            JSONArray()
        } else {
            try {
                JSONArray(existingString)
            } catch (e: Exception) {
                JSONArray()
            }
        }

        val deduplicatedSessions = JSONArray()

        for (i in 0 until existingSessions.length()) {
            val existing = existingSessions.optJSONObject(i) ?: continue

            if (existing.optString("sessionId") != sessionId) {
                deduplicatedSessions.put(existing)
            }
        }

        val newSession = JSONObject()
            .put("sessionId", sessionId)
            .put("source", source)
            .put("schemaVersion", schemaVersion)
            .put("workoutStartedAtMillis", workoutStartedAtMillis)
            .put("workoutEndedAtMillis", workoutEndedAtMillis)
            .put("recoveryEndedAtMillis", recoveryEndedAtMillis)
            .put("receivedAtMillis", receivedAtMillis)
            .put("peakHr", peakHr)
            .put("workoutEndHr", workoutEndHr)
            .put("hr60", hr60)
            .put("hr120", hr120)
            .put("sampleCount", sampleCount)
            .put("maxHr", maxHr)
            .put("durationSeconds", durationSeconds)
            .put("importStatus", "pending")
            .put("payload", payload)

        val finalSessions = JSONArray()
        finalSessions.put(newSession)

        for (i in 0 until deduplicatedSessions.length()) {
            finalSessions.put(deduplicatedSessions.getJSONObject(i))
        }

        prefs.edit()
            .putString(RECEIVED_SESSIONS_KEY, finalSessions.toString())
            .apply()

        Log.i(TAG, "Saved received session locally on phone: $sessionId")
    }

    private fun sendAckToWatch(
        sourceNodeId: String?,
        sessionId: String
    ) {
        if (sourceNodeId.isNullOrBlank()) {
            Log.w(TAG, "Cannot ACK session $sessionId because source node was blank")
            return
        }

        Wearable.getMessageClient(this)
            .sendMessage(
                sourceNodeId,
                HR_SESSION_ACK_PATH,
                sessionId.toByteArray(StandardCharsets.UTF_8)
            )
            .addOnSuccessListener {
                Log.i(TAG, "Sent ACK to watch for session: $sessionId")
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Failed to send ACK for session $sessionId: ${e.message}")
            }
    }

    private fun calculateMaxHr(points: JSONArray): Int {
        var maxHr = 0.0

        for (i in 0 until points.length()) {
            val point = points.optJSONObject(i) ?: continue
            val bpm = point.optDouble("bpm", 0.0)

            if (bpm > maxHr) {
                maxHr = bpm
            }
        }

        return maxHr.toInt()
    }

    private fun calculateDurationSeconds(
        startMillis: Long,
        endMillis: Long?
    ): Int {
        if (startMillis <= 0L || endMillis == null || endMillis <= startMillis) {
            return 0
        }

        return ((endMillis - startMillis) / 1000L).toInt()
    }

    private fun nullableLong(obj: JSONObject, key: String): Long? {
        return if (obj.has(key) && !obj.isNull(key)) {
            obj.optLong(key)
        } else {
            null
        }
    }

    private fun nullableDouble(obj: JSONObject, key: String): Double? {
        return if (obj.has(key) && !obj.isNull(key)) {
            obj.optDouble(key)
        } else {
            null
        }
    }
}