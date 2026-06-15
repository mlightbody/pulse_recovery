package com.example.pulserecoverywear.model

data class HrSession(
    val sessionId: String,
    val source: String = "galaxy_watch",

    val workoutStartedAtMillis: Long,
    val workoutEndedAtMillis: Long?,
    val recoveryEndedAtMillis: Long?,

    val peakHr: Double?,
    val workoutEndHr: Double?,
    val hr60: Double?,
    val hr120: Double?,

    val points: List<HrPoint>,

    val syncStatus: String = "PENDING",
    val importStatus: String = "NOT_IMPORTED"
)