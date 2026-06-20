package com.example.pulserecoverywear.presentation

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.unregisterMeasureCallback
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DeltaDataType
import androidx.lifecycle.lifecycleScope
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import com.example.pulserecoverywear.model.HrPoint
import com.example.pulserecoverywear.model.HrSession
import com.example.pulserecoverywear.presentation.theme.PulseRecoveryWearTheme
import com.example.pulserecoverywear.storage.HrSessionStore
import com.example.pulserecoverywear.sync.WatchSessionSync
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.abs

enum class RecordingState {
    IDLE,
    WORKOUT,
    RECOVERY,
    SAVED
}

class MainActivity : ComponentActivity() {

    companion object {
        private const val RECOVERY_DURATION_SECONDS = 120
        private const val NEAREST_POINT_TOLERANCE_MILLIS = 10_000L
    }

    private val measureClient by lazy {
        HealthServices.getClient(this).measureClient
    }

    private lateinit var sessionStore: HrSessionStore
    private lateinit var sessionSync: WatchSessionSync

    private val recordedPoints = mutableListOf<HrPoint>()

    private var recordingState by mutableStateOf(RecordingState.IDLE)

    private var currentBpm by mutableDoubleStateOf(0.0)
    private var maxBpm by mutableDoubleStateOf(0.0)
    private var elapsedSeconds by mutableDoubleStateOf(0.0)

    private var workoutEndHr by mutableDoubleStateOf(0.0)
    private var hr60 by mutableDoubleStateOf(0.0)
    private var hr120 by mutableDoubleStateOf(0.0)

    private var sampleCount by mutableIntStateOf(0)
    private var pendingCount by mutableIntStateOf(0)
    private var recoveryElapsedSeconds by mutableIntStateOf(0)

    private var workoutStartMillis by mutableLongStateOf(0L)
    private var workoutEndMillis by mutableLongStateOf(0L)

    private var statusText by mutableStateOf("Ready")
    private var syncStatusText by mutableStateOf("Sync: not attempted")
    private var debugStatusText by mutableStateOf("Debug: not checked")

    private var syncButtonText by mutableStateOf("Sync Now")
    private var debugButtonText by mutableStateOf("Debug Status")
    private var cleanButtonText by mutableStateOf("Clean Synced")

    private var syncInProgress by mutableStateOf(false)

    private var recoveryJob: Job? = null

    private val bodySensorPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            statusText = if (granted) {
                "BODY_SENSORS permission granted"
            } else {
                "BODY_SENSORS permission denied"
            }
        }

    private val heartRateCallback = object : MeasureCallback {

        override fun onAvailabilityChanged(
            dataType: DeltaDataType<*, *>,
            availability: Availability
        ) {
            runOnUiThread {
                statusText = "Sensor: $availability"
            }
        }

        override fun onDataReceived(data: DataPointContainer) {
            val points = data.getData(DataType.HEART_RATE_BPM)

            if (points.isEmpty()) {
                return
            }

            runOnUiThread {
                val now = System.currentTimeMillis()

                if (workoutStartMillis == 0L) {
                    workoutStartMillis = now
                }

                for (point in points) {
                    val bpm = point.value
                    val elapsed = (now - workoutStartMillis) / 1000.0

                    recordedPoints.add(
                        HrPoint(
                            elapsedSeconds = elapsed,
                            bpm = bpm,
                            timestampMillis = now
                        )
                    )

                    currentBpm = bpm
                    elapsedSeconds = elapsed

                    if (recordingState == RecordingState.WORKOUT) {
                        maxBpm = maxOf(maxBpm, bpm)
                    }
                }

                sampleCount = recordedPoints.size

                if (recordingState == RecordingState.WORKOUT) {
                    statusText = "Workout recording"
                }

                if (recordingState == RecordingState.RECOVERY) {
                    statusText = "Recovery recording"
                    updateRecoveryValuesForDisplay()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep the watch screen awake while this Activity is open.
        // This is the least invasive workaround for MeasureClient pausing
        // heart-rate updates when the watch screen blanks.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        sessionStore = HrSessionStore(this)
        sessionSync = WatchSessionSync(this)

        pendingCount = sessionStore.unsyncedCount()
        debugStatusText = statusSummary()

        requestBodySensorPermissionIfNeeded()

        setContent {
            PulseRecoveryWearTheme {
                AppScaffold {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp)
                            .verticalScroll(rememberScrollState()),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Top
                    ) {
                        Text(
                            text = "Pulse Recovery",
                            style = MaterialTheme.typography.titleMedium
                        )

                        Text(
                            text = recordingState.name,
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = if (currentBpm > 0) {
                                "${currentBpm.toInt()} bpm"
                            } else {
                                "-- bpm"
                            },
                            style = MaterialTheme.typography.displayMedium
                        )

                        Text(
                            text = statusText,
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "Workout: ${formatSeconds(elapsedSeconds.toInt())}",
                            style = MaterialTheme.typography.bodySmall
                        )

                        if (recordingState == RecordingState.RECOVERY) {
                            Text(
                                text = "Recovery: ${recoveryElapsedSeconds}s / ${RECOVERY_DURATION_SECONDS}s",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }

                        Text(
                            text = "Samples: $sampleCount",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "Peak: ${formatBpm(maxBpm)}",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "End: ${formatBpm(workoutEndHr)}",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "60s: ${formatBpm(hr60)}",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "120s: ${formatBpm(hr120)}",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = "Pending: $pendingCount",
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = syncStatusText,
                            style = MaterialTheme.typography.bodySmall
                        )

                        Text(
                            text = debugStatusText,
                            style = MaterialTheme.typography.bodySmall
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Button(
                                onClick = { startWorkout() },
                                modifier = Modifier.weight(1f),
                                enabled = recordingState == RecordingState.IDLE ||
                                        recordingState == RecordingState.SAVED
                            ) {
                                Text("Start")
                            }

                            Button(
                                onClick = { endWorkoutAndStartRecovery() },
                                modifier = Modifier.weight(1f),
                                enabled = recordingState == RecordingState.WORKOUT
                            ) {
                                Text("Stop")
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Button(
                            onClick = { queuePendingSessionsForSync() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !syncInProgress &&
                                    (recordingState == RecordingState.IDLE ||
                                            recordingState == RecordingState.SAVED)
                        ) {
                            Text(syncButtonText)
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Button(
                            onClick = { refreshStoredSessionDebugStatusFromButton() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = recordingState == RecordingState.IDLE ||
                                    recordingState == RecordingState.SAVED
                        ) {
                            Text(debugButtonText)
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Button(
                            onClick = { cleanSyncedSessionsFromButton() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = recordingState == RecordingState.IDLE ||
                                    recordingState == RecordingState.SAVED
                        ) {
                            Text(cleanButtonText)
                        }
                    }
                }
            }
        }
    }

    private fun requestBodySensorPermissionIfNeeded() {
        val permission = Manifest.permission.BODY_SENSORS

        if (ContextCompat.checkSelfPermission(this, permission) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            bodySensorPermissionLauncher.launch(permission)
        }
    }

    private fun startWorkout() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            statusText = "Requesting BODY_SENSORS permission..."
            requestBodySensorPermissionIfNeeded()
            return
        }

        // Re-apply this when recording starts, in case the Activity was recreated
        // or the flag was cleared by lifecycle changes.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        resetCurrentSession()

        workoutStartMillis = System.currentTimeMillis()
        recordingState = RecordingState.WORKOUT
        statusText = "Starting workout..."
        syncStatusText = "Sync: not attempted"
        debugStatusText = statusSummary()

        syncButtonText = "Sync Now"
        debugButtonText = "Debug Status"
        cleanButtonText = "Clean Synced"
        syncInProgress = false

        lifecycleScope.launch {
            try {
                measureClient.registerMeasureCallback(
                    DataType.HEART_RATE_BPM,
                    heartRateCallback
                )

                statusText = "Workout recording"
            } catch (e: Exception) {
                statusText = "Start failed: ${e.message}"
                recordingState = RecordingState.IDLE
            }
        }
    }

    private fun endWorkoutAndStartRecovery() {
        if (recordingState != RecordingState.WORKOUT) {
            return
        }

        workoutEndMillis = System.currentTimeMillis()

        workoutEndHr = nearestBpmToTimestamp(
            targetMillis = workoutEndMillis,
            points = recordedPoints,
            toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
        ) ?: currentBpm

        recordingState = RecordingState.RECOVERY
        recoveryElapsedSeconds = 0
        statusText = "Recovery started"

        recoveryJob?.cancel()
        recoveryJob = lifecycleScope.launch {
            while (recoveryElapsedSeconds < RECOVERY_DURATION_SECONDS) {
                delay(1000L)
                recoveryElapsedSeconds += 1
                updateRecoveryValuesForDisplay()
            }

            finishRecoveryAndSave()
        }
    }

    private fun updateRecoveryValuesForDisplay() {
        if (workoutEndMillis <= 0L) {
            return
        }

        if (recoveryElapsedSeconds >= 60) {
            hr60 = nearestBpmToTimestamp(
                targetMillis = workoutEndMillis + 60_000L,
                points = recordedPoints,
                toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
            ) ?: hr60
        }

        if (recoveryElapsedSeconds >= 120) {
            hr120 = nearestBpmToTimestamp(
                targetMillis = workoutEndMillis + 120_000L,
                points = recordedPoints,
                toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
            ) ?: hr120
        }
    }

    private fun finishRecoveryAndSave() {
        lifecycleScope.launch {
            try {
                measureClient.unregisterMeasureCallback(
                    DataType.HEART_RATE_BPM,
                    heartRateCallback
                )
            } catch (_: Exception) {
                // We still try to save the session even if unregister throws.
            }

            val session = buildCompletedSession()

            if (session == null) {
                statusText = "No HR points to save"
                recordingState = RecordingState.IDLE
                refreshStoredSessionDebugStatus()
                return@launch
            }

            sessionStore.saveSession(session)
            refreshStoredSessionDebugStatus()

            statusText = "Saved recovery session"
            recordingState = RecordingState.SAVED

            queueSessionForSync(session)
        }
    }

    private fun buildCompletedSession(): HrSession? {
        if (recordedPoints.isEmpty() || workoutStartMillis <= 0L || workoutEndMillis <= 0L) {
            return null
        }

        val recoveryEndMillis = System.currentTimeMillis()

        val finalWorkoutEndHr = nearestBpmToTimestamp(
            targetMillis = workoutEndMillis,
            points = recordedPoints,
            toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
        ) ?: workoutEndHr.takeIf { it > 0.0 }

        val finalHr60 = nearestBpmToTimestamp(
            targetMillis = workoutEndMillis + 60_000L,
            points = recordedPoints,
            toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
        )

        val finalHr120 = nearestBpmToTimestamp(
            targetMillis = workoutEndMillis + 120_000L,
            points = recordedPoints,
            toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
        )

        val finalPeakHr = peakWorkoutBpm(
            workoutEndMillis = workoutEndMillis,
            points = recordedPoints
        )

        workoutEndHr = finalWorkoutEndHr ?: 0.0
        hr60 = finalHr60 ?: 0.0
        hr120 = finalHr120 ?: 0.0
        maxBpm = finalPeakHr ?: maxBpm

        return HrSession(
            sessionId = "galaxy_$workoutStartMillis",
            source = "galaxy_watch",
            workoutStartedAtMillis = workoutStartMillis,
            workoutEndedAtMillis = workoutEndMillis,
            recoveryEndedAtMillis = recoveryEndMillis,
            peakHr = finalPeakHr,
            workoutEndHr = finalWorkoutEndHr,
            hr60 = finalHr60,
            hr120 = finalHr120,
            points = recordedPoints.toList(),
            syncStatus = "PENDING",
            importStatus = "NOT_IMPORTED"
        )
    }

    private fun queueSessionForSync(session: HrSession) {
        syncStatusText = "Sync: queueing..."

        sessionSync.sendSession(session) { success, message ->
            runOnUiThread {
                if (success) {
                    sessionStore.markSessionQueued(session.sessionId)
                }

                refreshStoredSessionDebugStatus()
                syncStatusText = "Sync: $message"
            }
        }
    }

    private fun queuePendingSessionsForSync() {
        refreshStoredSessionDebugStatus()

        syncInProgress = true
        syncButtonText = "Syncing..."
        syncStatusText = "Sync: queueing pending..."

        sessionSync.sendPendingSessions(sessionStore) { success, message ->
            runOnUiThread {
                refreshStoredSessionDebugStatus()

                syncStatusText = if (success) {
                    "Sync: $message"
                } else {
                    "Sync issue: $message"
                }

                syncButtonText = if (success) {
                    "Synced ✓"
                } else {
                    "Sync issue"
                }

                syncInProgress = false

                lifecycleScope.launch {
                    delay(1500L)
                    syncButtonText = "Sync Now"
                }
            }
        }
    }

    private fun refreshStoredSessionDebugStatus() {
        pendingCount = sessionStore.unsyncedCount()
        debugStatusText = statusSummary()
    }

    private fun refreshStoredSessionDebugStatusFromButton() {
        refreshStoredSessionDebugStatus()

        debugButtonText = "Checked ✓"

        lifecycleScope.launch {
            delay(1200L)
            debugButtonText = "Debug Status"
        }
    }

    private fun cleanSyncedSessionsFromButton() {
        sessionStore.deleteSyncedSessions()
        refreshStoredSessionDebugStatus()

        syncStatusText = "Deleted synced sessions"
        cleanButtonText = "Cleaned ✓"

        lifecycleScope.launch {
            delay(1200L)
            cleanButtonText = "Clean Synced"
        }
    }

    private fun statusSummary(): String {
        val sessions = sessionStore.loadAllSessions()

        val pending = sessions.count { it.syncStatus == "PENDING" }
        val queued = sessions.count { it.syncStatus == "QUEUED" }
        val synced = sessions.count { it.syncStatus == "SYNCED" }

        return "Debug: Total ${sessions.size}, P $pending, Q $queued, S $synced"
    }

    private fun resetCurrentSession() {
        recoveryJob?.cancel()
        recoveryJob = null

        recordedPoints.clear()

        recordingState = RecordingState.IDLE

        currentBpm = 0.0
        maxBpm = 0.0
        elapsedSeconds = 0.0

        workoutEndHr = 0.0
        hr60 = 0.0
        hr120 = 0.0

        sampleCount = 0
        recoveryElapsedSeconds = 0

        workoutStartMillis = 0L
        workoutEndMillis = 0L

        statusText = "Ready"
    }

    private fun nearestBpmToTimestamp(
        targetMillis: Long,
        points: List<HrPoint>,
        toleranceMillis: Long
    ): Double? {
        if (points.isEmpty()) {
            return null
        }

        val nearest = points.minByOrNull { point ->
            abs(point.timestampMillis - targetMillis)
        } ?: return null

        val distance = abs(nearest.timestampMillis - targetMillis)

        return if (distance <= toleranceMillis) {
            nearest.bpm
        } else {
            null
        }
    }

    private fun peakWorkoutBpm(
        workoutEndMillis: Long,
        points: List<HrPoint>
    ): Double? {
        return points
            .filter { it.timestampMillis <= workoutEndMillis }
            .maxOfOrNull { it.bpm }
    }

    private fun formatBpm(value: Double): String {
        return if (value > 0.0) {
            "${value.toInt()} bpm"
        } else {
            "--"
        }
    }

    private fun formatSeconds(totalSeconds: Int): String {
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60

        return if (minutes > 0) {
            String.format(Locale.UK, "%dm %02ds", minutes, seconds)
        } else {
            "${seconds}s"
        }
    }

    override fun onDestroy() {
        recoveryJob?.cancel()

        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        if (recordingState == RecordingState.WORKOUT ||
            recordingState == RecordingState.RECOVERY
        ) {
            lifecycleScope.launch {
                try {
                    measureClient.unregisterMeasureCallback(
                        DataType.HEART_RATE_BPM,
                        heartRateCallback
                    )
                } catch (_: Exception) {
                    // Ignore cleanup failure during destroy.
                }
            }
        }

        super.onDestroy()
    }
}