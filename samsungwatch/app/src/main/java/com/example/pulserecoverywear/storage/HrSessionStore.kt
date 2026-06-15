package com.example.pulserecoverywear.storage

import android.content.Context
import com.example.pulserecoverywear.model.HrPoint
import com.example.pulserecoverywear.model.HrSession
import org.json.JSONArray
import org.json.JSONObject

class HrSessionStore(private val context: Context) {

    private val prefs = context.getSharedPreferences(
        "hr_session_store",
        Context.MODE_PRIVATE
    )

    private val sessionsKey = "sessions"

    fun saveSession(session: HrSession) {
        val sessions = loadAllSessions().toMutableList()

        sessions.removeAll { it.sessionId == session.sessionId }
        sessions.add(session)

        saveAllSessions(sessions)
    }

    fun loadAllSessions(): List<HrSession> {
        val jsonString = prefs.getString(sessionsKey, null) ?: return emptyList()

        return try {
            val array = JSONArray(jsonString)
            val sessions = mutableListOf<HrSession>()

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                sessions.add(jsonToSession(obj))
            }

            sessions
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun loadPendingSessions(): List<HrSession> {
        return loadAllSessions().filter {
            it.syncStatus == "PENDING" || it.syncStatus == "QUEUED"
        }
    }

    fun markSessionQueued(sessionId: String) {
        val sessions = loadAllSessions().map { session ->
            if (session.sessionId == sessionId) {
                session.copy(syncStatus = "QUEUED")
            } else {
                session
            }
        }

        saveAllSessions(sessions)
    }

    fun markSessionSynced(sessionId: String) {
        val sessions = loadAllSessions().map { session ->
            if (session.sessionId == sessionId) {
                session.copy(syncStatus = "SYNCED")
            } else {
                session
            }
        }

        saveAllSessions(sessions)
    }

    fun unsyncedCount(): Int {
        return loadAllSessions().count {
            it.syncStatus == "PENDING" || it.syncStatus == "QUEUED"
        }
    }

    fun deleteSyncedSessions() {
        val sessions = loadAllSessions().filter {
            it.syncStatus != "SYNCED"
        }

        saveAllSessions(sessions)
    }

    private fun saveAllSessions(sessions: List<HrSession>) {
        val array = JSONArray()

        sessions.forEach { session ->
            array.put(sessionToJson(session))
        }

        prefs.edit()
            .putString(sessionsKey, array.toString())
            .apply()
    }

    private fun sessionToJson(session: HrSession): JSONObject {
        val pointsArray = JSONArray()

        session.points.forEach { point ->
            val pointObj = JSONObject()
                .put("elapsedSeconds", point.elapsedSeconds)
                .put("bpm", point.bpm)
                .put("timestampMillis", point.timestampMillis)

            pointsArray.put(pointObj)
        }

        return JSONObject()
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
    }

    private fun jsonToSession(obj: JSONObject): HrSession {
        val pointsArray = obj.optJSONArray("points") ?: JSONArray()
        val points = mutableListOf<HrPoint>()

        for (i in 0 until pointsArray.length()) {
            val pointObj = pointsArray.getJSONObject(i)

            points.add(
                HrPoint(
                    elapsedSeconds = pointObj.optDouble("elapsedSeconds", 0.0),
                    bpm = pointObj.optDouble("bpm", 0.0),
                    timestampMillis = pointObj.optLong("timestampMillis", 0L)
                )
            )
        }

        return HrSession(
            sessionId = obj.optString("sessionId", "unknown_${System.currentTimeMillis()}"),
            source = obj.optString("source", "galaxy_watch"),

            workoutStartedAtMillis = obj.optLong(
                "workoutStartedAtMillis",
                obj.optLong("startedAtMillis", 0L)
            ),

            workoutEndedAtMillis = nullableLong(obj, "workoutEndedAtMillis")
                ?: nullableLong(obj, "endedAtMillis"),

            recoveryEndedAtMillis = nullableLong(obj, "recoveryEndedAtMillis"),

            peakHr = nullableDouble(obj, "peakHr"),
            workoutEndHr = nullableDouble(obj, "workoutEndHr"),
            hr60 = nullableDouble(obj, "hr60"),
            hr120 = nullableDouble(obj, "hr120"),

            points = points,

            syncStatus = obj.optString("syncStatus", "PENDING"),
            importStatus = obj.optString("importStatus", "NOT_IMPORTED")
        )
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