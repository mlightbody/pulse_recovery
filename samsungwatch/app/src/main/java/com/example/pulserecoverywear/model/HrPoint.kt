package com.example.pulserecoverywear.model

data class HrPoint(
    val elapsedSeconds: Double,
    val bpm: Double,
    val timestampMillis: Long
)