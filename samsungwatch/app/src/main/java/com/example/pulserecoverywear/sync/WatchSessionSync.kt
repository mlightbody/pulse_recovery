package com.example.pulserecoverywear.sync

import android.content.Context
import com.example.pulserecoverywear.model.HrSession
import com.example.pulserecoverywear.storage.HrSessionStore
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import org.json.JSONArray
import org.json.JSONObject

class WatchSessionSync(private val context: Context) {

    companion object {
        private const val HR_SESSION_PATH_PREFIX = "/hr_session"
    }

    fun sendSession(
        session: HrSession,
        onComplete: (success: Boolean, message: String) -> Unit
    ) {
        try {
            val payloadJson = sessionToJson(session)

            val request = PutDataMapRequest.create(
                "$HR_SESSION_PATH_PREFIX/${session.sessionId}"
            ).apply {
                dataMap.putInt("schemaVersion", 2)
                dataMap.putString("sessionId", session.sessionId)
                dataMap.putString("source", session.source)
                dataMap.putLong("workoutStartedAtMillis", session.workoutStartedAtMillis)
                dataMap.putLong("workoutEndedAtMillis", session.workoutEndedAtMillis ?: 0L)
                dataMap.putLong("recoveryEndedAtMillis", session.recoveryEndedAtMillis ?: 0L)

                dataMap.putDouble("peakHr", session.peakHr ?: 0.0)
                dataMap.putDouble("workoutEndHr", session.workoutEndHr ?: 0.0)
                dataMap.putDouble("hr60", session.hr60 ?: 0.0)
                dataMap.putDouble("hr120", session.hr120 ?: 0.0)

                dataMap.putString("payload", payloadJson)

                dataMap.putLong("updatedAtMillis", System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()

            Wearable.getDataClient(context)
                .putDataItem(request)
                .addOnSuccessListener {
                    onComplete(true, "Queued for phone sync")
                }
                .addOnFailureListener { e ->
                    onComplete(false, "Queue failed: ${e.message ?: "unknown error"}")
                }
        } catch (e: Exception) {
            onComplete(false, "Queue failed: ${e.message ?: "unknown error"}")
        }
    }

    fun sendPendingSessions(
        store: HrSessionStore,
        onComplete: (success: Boolean, message: String) -> Unit
    ) {
        val pending = store.loadPendingSessions()

        if (pending.isEmpty()) {
            onComplete(true, "No pending sessions")
            return
        }

        var completed = 0
        var successes = 0
        var failures = 0

        pending.forEach { session ->
            sendSession(session) { success, _ ->
                completed += 1

                if (success) {
                    successes += 1
                    store.markSessionQueued(session.sessionId)
                } else {
                    failures += 1
                }

                if (completed == pending.size) {
                    onComplete(
                        failures == 0,
                        "Queued $successes, failed $failures"
                    )
                }
            }
        }
    }

    private fun sessionToJson(session: HrSession): String {
        val pointsArray = JSONArray()

        session.points.forEach { point ->
            val pointObj = JSONObject()
                .put("elapsedSeconds", point.elapsedSeconds)
                .put("bpm", point.bpm)
                .put("timestampMillis", point.timestampMillis)

            pointsArray.put(pointObj)
        }

        return JSONObject()
            .put("schemaVersion", 2)
            .put("sessionId", session.sessionId)
            .put("source", session.source)
            .put("workoutStartedAtMillis", session.workoutStartedAtMillis)
            .put("workoutEndedAtMillis", session.workoutEndedAtMillis)
            .put("recoveryEndedAtMillis", session.recoveryEndedAtMillis)
            .put("peakHr", session.peakHr)
            .put("workoutEndHr", session.workoutEndHr)
            .put("hr60", session.hr60)
            .put("hr120", session.hr120)
            .put("syncStatus", session.syncStatus)
            .put("importStatus", session.importStatus)
            .put("points", pointsArray)
            .toString()
    }
}