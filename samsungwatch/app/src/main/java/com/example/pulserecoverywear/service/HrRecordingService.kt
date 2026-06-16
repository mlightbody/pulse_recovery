package com.example.pulserecoverywear.service

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.content.ContextCompat
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseLapSummary
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.ExerciseUpdate
import com.example.pulserecoverywear.model.HrPoint
import com.example.pulserecoverywear.model.HrSession
import com.example.pulserecoverywear.presentation.MainActivity
import com.example.pulserecoverywear.storage.HrSessionStore
import com.example.pulserecoverywear.sync.WatchSessionSync
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.abs

enum class RecordingState {
    IDLE,
    WORKOUT,
    RECOVERY,
    SAVED
}

data class HrRecordingUiState(
    val recordingState: RecordingState = RecordingState.IDLE,
    val currentBpm: Double = 0.0,
    val maxBpm: Double = 0.0,
    val elapsedSeconds: Double = 0.0,
    val workoutEndHr: Double = 0.0,
    val hr60: Double = 0.0,
    val hr120: Double = 0.0,
    val sampleCount: Int = 0,
    val pendingCount: Int = 0,
    val recoveryElapsedSeconds: Int = 0,
    val statusText: String = "Ready",
    val syncStatusText: String = "Sync: not attempted",
    val debugStatusText: String = "Debug: not checked"
)

class HrRecordingService : Service() {

    companion object {
        const val ACTION_START_WORKOUT =
            "com.example.pulserecoverywear.action.START_WORKOUT"
        const val ACTION_STOP_WORKOUT =
            "com.example.pulserecoverywear.action.STOP_WORKOUT"
        const val ACTION_SYNC_NOW =
            "com.example.pulserecoverywear.action.SYNC_NOW"
        const val ACTION_CLEAN_SYNCED =
            "com.example.pulserecoverywear.action.CLEAN_SYNCED"
        const val ACTION_STOP_SERVICE =
            "com.example.pulserecoverywear.action.STOP_SERVICE"

        private const val RECOVERY_DURATION_SECONDS = 120
        private const val NEAREST_POINT_TOLERANCE_MILLIS = 30_000L

        private const val NOTIFICATION_CHANNEL_ID = "hr_recording_channel"
        private const val NOTIFICATION_CHANNEL_NAME = "HR recording"
        private const val NOTIFICATION_ID = 1001
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): HrRecordingService = this@HrRecordingService
    }

    private val serviceScope =
        CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val exerciseClient by lazy {
        HealthServices.getClient(this).exerciseClient
    }

    private lateinit var sessionStore: HrSessionStore
    private lateinit var sessionSync: WatchSessionSync

    private val recordedPoints = mutableListOf<HrPoint>()

    private val _uiState = MutableStateFlow(HrRecordingUiState())
    val uiState: StateFlow<HrRecordingUiState> = _uiState.asStateFlow()

    private var recoveryJob: Job? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var workoutStartMillis = 0L
    private var workoutEndMillis = 0L

    private var currentBpm = 0.0
    private var maxBpm = 0.0
    private var elapsedSeconds = 0.0

    private var workoutEndHr = 0.0
    private var hr60 = 0.0
    private var hr120 = 0.0

    private var recoveryElapsedSeconds = 0
    private var recordingState = RecordingState.IDLE

    private var isForeground = false
    private var exerciseStarted = false
    private var finishingExercise = false

    private val exerciseUpdateCallback = object : ExerciseUpdateCallback {
        override fun onRegistered() {
            serviceScope.launch {
                updateState {
                    it.copy(statusText = "Exercise callback registered")
                }
                updateNotification()
            }
        }

        override fun onRegistrationFailed(throwable: Throwable) {
            serviceScope.launch {
                updateState {
                    it.copy(
                        statusText = "Exercise callback failed: ${throwable.message}"
                    )
                }
                updateNotification()
            }
        }

        override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
            serviceScope.launch {
                handleExerciseUpdate(update)
            }
        }

        override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) {
            // We do not use laps for Pulse Recovery.
        }

        override fun onAvailabilityChanged(
            dataType: DataType<*, *>,
            availability: Availability
        ) {
            serviceScope.launch {
                updateState {
                    it.copy(statusText = "Sensor: $availability")
                }
                updateNotification()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()

        sessionStore = HrSessionStore(this)
        sessionSync = WatchSessionSync(this)

        createNotificationChannel()

        updateState {
            it.copy(
                pendingCount = sessionStore.unsyncedCount(),
                debugStatusText = statusSummary()
            )
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        when (intent?.action) {
            ACTION_START_WORKOUT -> startWorkout()
            ACTION_STOP_WORKOUT -> endWorkoutAndStartRecovery()
            ACTION_SYNC_NOW -> queuePendingSessionsForSync()
            ACTION_CLEAN_SYNCED -> deleteSyncedSessions()
            ACTION_STOP_SERVICE -> stopServiceIfIdle()
        }

        return START_STICKY
    }

    fun startWorkout() {
        if (recordingState == RecordingState.WORKOUT ||
            recordingState == RecordingState.RECOVERY
        ) {
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            updateState {
                it.copy(statusText = "BODY_SENSORS permission missing")
            }
            return
        }

        resetCurrentSession()

        workoutStartMillis = System.currentTimeMillis()
        recordingState = RecordingState.WORKOUT
        exerciseStarted = false
        finishingExercise = false

        publishUiState(statusText = "Starting ExerciseClient...")
        acquireWakeLock()
        startForegroundRecording()

        try {
            exerciseClient.setUpdateCallback(exerciseUpdateCallback)

            val config = ExerciseConfig(
                exerciseType = ExerciseType.WORKOUT,
                dataTypes = setOf(
                    DataType.HEART_RATE_BPM
                ),
                isAutoPauseAndResumeEnabled = false,
                isGpsEnabled = false
            )

            listenToFuture(
                future = exerciseClient.startExerciseAsync(config),
                onSuccess = {
                    exerciseStarted = true
                    publishUiState(statusText = "Workout recording")
                    updateNotification()
                },
                onFailure = { error ->
                    recordingState = RecordingState.IDLE
                    exerciseStarted = false

                    publishUiState(
                        statusText = "Exercise start failed: ${error.message}"
                    )

                    stopForegroundRecording()
                    stopSelf()
                }
            )
        } catch (e: Exception) {
            recordingState = RecordingState.IDLE
            exerciseStarted = false

            publishUiState(
                statusText = "Exercise setup failed: ${e.message}"
            )

            stopForegroundRecording()
            stopSelf()
        }
    }

    fun endWorkoutAndStartRecovery() {
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

        publishUiState(statusText = "Recovery started")
        updateNotification()

        recoveryJob?.cancel()
        recoveryJob = serviceScope.launch {
            while (recoveryElapsedSeconds < RECOVERY_DURATION_SECONDS) {
                delay(1000L)

                recoveryElapsedSeconds += 1
                updateRecoveryValuesForDisplay()

                publishUiState(statusText = "Recovery recording")
                updateNotification()
            }

            finishRecoveryAndSave()
        }
    }

    fun queuePendingSessionsForSync() {
        refreshStoredSessionDebugStatus()

        updateState {
            it.copy(syncStatusText = "Sync: queueing pending...")
        }

        sessionSync.sendPendingSessions(sessionStore) { success, message ->
            serviceScope.launch {
                refreshStoredSessionDebugStatus()

                updateState {
                    it.copy(
                        syncStatusText = if (success) {
                            "Sync: $message"
                        } else {
                            "Sync issue: $message"
                        }
                    )
                }
            }
        }
    }

    fun deleteSyncedSessions() {
        if (recordingState == RecordingState.WORKOUT ||
            recordingState == RecordingState.RECOVERY
        ) {
            updateState {
                it.copy(syncStatusText = "Cannot clean while recording")
            }
            return
        }

        sessionStore.deleteSyncedSessions()
        refreshStoredSessionDebugStatus()

        updateState {
            it.copy(syncStatusText = "Deleted synced sessions")
        }
    }

    fun refreshStoredSessionDebugStatus() {
        updateState {
            it.copy(
                pendingCount = sessionStore.unsyncedCount(),
                debugStatusText = statusSummary()
            )
        }
    }

    private fun handleExerciseUpdate(update: ExerciseUpdate) {
        recordHeartRatePoints(update.latestMetrics)

        if (recordingState == RecordingState.RECOVERY) {
            updateRecoveryValuesForDisplay()
        }

        publishUiState(
            statusText = when (recordingState) {
                RecordingState.WORKOUT -> "Workout recording"
                RecordingState.RECOVERY -> "Recovery recording"
                RecordingState.SAVED -> "Saved recovery session"
                RecordingState.IDLE -> "Ready"
            }
        )

        updateNotification()

        if (update.exerciseStateInfo.state.isEnded &&
            !finishingExercise &&
            (recordingState == RecordingState.WORKOUT ||
                    recordingState == RecordingState.RECOVERY)
        ) {
            publishUiState(statusText = "Exercise ended by system")
            finishRecoveryAndSave()
        }
    }

    private fun recordHeartRatePoints(metrics: DataPointContainer) {
        val points = metrics.getData(DataType.HEART_RATE_BPM)

        if (points.isEmpty()) {
            return
        }

        for (point in points) {
            val bpm = point.value
            val timestampMillis = System.currentTimeMillis()

            val elapsed = if (workoutStartMillis > 0L) {
                (timestampMillis - workoutStartMillis) / 1000.0
            } else {
                0.0
            }

            recordedPoints.add(
                HrPoint(
                    elapsedSeconds = elapsed,
                    bpm = bpm,
                    timestampMillis = timestampMillis
                )
            )

            currentBpm = bpm
            elapsedSeconds = elapsed.coerceAtLeast(0.0)

            if (recordingState == RecordingState.WORKOUT &&
                (workoutEndMillis <= 0L || timestampMillis <= workoutEndMillis)
            ) {
                maxBpm = maxOf(maxBpm, bpm)
            }
        }

        recordedPoints.sortBy { it.timestampMillis }
    }

    private fun finishRecoveryAndSave() {
        if (finishingExercise) {
            return
        }

        finishingExercise = true
        recoveryJob?.cancel()
        recoveryJob = null

        publishUiState(statusText = "Flushing HR samples...")

        if (!exerciseStarted) {
            saveCompletedSessionAndSync()
            return
        }

        listenToFuture(
            future = exerciseClient.flushAsync(),
            onSuccess = {
                serviceScope.launch {
                    delay(750L)
                    endExerciseThenSave()
                }
            },
            onFailure = {
                serviceScope.launch {
                    delay(750L)
                    endExerciseThenSave()
                }
            }
        )
    }

    private fun endExerciseThenSave() {
        publishUiState(statusText = "Ending ExerciseClient...")

        listenToFuture(
            future = exerciseClient.endExerciseAsync(),
            onSuccess = {
                serviceScope.launch {
                    delay(750L)
                    clearExerciseCallback()
                    exerciseStarted = false
                    saveCompletedSessionAndSync()
                }
            },
            onFailure = {
                serviceScope.launch {
                    clearExerciseCallback()
                    exerciseStarted = false
                    saveCompletedSessionAndSync()
                }
            }
        )
    }

    private fun saveCompletedSessionAndSync() {
        val session = buildCompletedSession()

        if (session == null) {
            recordingState = RecordingState.IDLE
            publishUiState(statusText = "No HR points to save")
            refreshStoredSessionDebugStatus()
            stopForegroundRecording()
            stopSelf()
            return
        }

        sessionStore.saveSession(session)
        refreshStoredSessionDebugStatus()

        recordingState = RecordingState.SAVED
        publishUiState(statusText = "Saved recovery session")

        queueSessionForSync(session)
    }

    private fun buildCompletedSession(): HrSession? {
        if (recordedPoints.isEmpty() ||
            workoutStartMillis <= 0L ||
            workoutEndMillis <= 0L
        ) {
            return null
        }

        val recoveryEndMillis = System.currentTimeMillis()

        val finalWorkoutEndHr = bestBpmForRecoveryTarget(
            targetMillis = workoutEndMillis
        ) ?: workoutEndHr.takeIf { it > 0.0 }

        val finalHr60 = bestBpmForRecoveryTarget(
            targetMillis = workoutEndMillis + 60_000L
        ) ?: hr60.takeIf { it > 0.0 }

        val finalHr120 = bestBpmForRecoveryTarget(
            targetMillis = workoutEndMillis + 120_000L
        ) ?: hr120.takeIf { it > 0.0 }

        val finalPeakHr = peakWorkoutBpm(
            workoutEndMillis = workoutEndMillis,
            points = recordedPoints
        )

        workoutEndHr = finalWorkoutEndHr ?: 0.0
        hr60 = finalHr60 ?: 0.0
        hr120 = finalHr120 ?: 0.0
        maxBpm = finalPeakHr ?: maxBpm

        publishUiState(statusText = "Saving recovery session")

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
        updateState {
            it.copy(syncStatusText = "Sync: queueing...")
        }

        sessionSync.sendSession(session) { success, message ->
            serviceScope.launch {
                if (success) {
                    sessionStore.markSessionQueued(session.sessionId)
                }

                refreshStoredSessionDebugStatus()

                updateState {
                    it.copy(syncStatusText = "Sync: $message")
                }

                updateNotification()

                stopForegroundRecording()
                stopSelf()
            }
        }
    }

    private fun updateRecoveryValuesForDisplay() {
        if (workoutEndMillis <= 0L) {
            return
        }

        if (recoveryElapsedSeconds >= 60 && hr60 <= 0.0) {
            hr60 = bestBpmForRecoveryTarget(
                targetMillis = workoutEndMillis + 60_000L
            ) ?: currentBpm
        }

        if (recoveryElapsedSeconds >= 120 && hr120 <= 0.0) {
            hr120 = bestBpmForRecoveryTarget(
                targetMillis = workoutEndMillis + 120_000L
            ) ?: currentBpm
        }
    }

    private fun bestBpmForRecoveryTarget(
        targetMillis: Long
    ): Double? {
        if (recordedPoints.isEmpty()) {
            return null
        }

        val nearest = nearestBpmToTimestamp(
            targetMillis = targetMillis,
            points = recordedPoints,
            toleranceMillis = NEAREST_POINT_TOLERANCE_MILLIS
        )

        if (nearest != null) {
            return nearest
        }

        val latestBeforeTarget = recordedPoints
            .filter { it.timestampMillis <= targetMillis }
            .maxByOrNull { it.timestampMillis }
            ?.bpm

        if (latestBeforeTarget != null) {
            return latestBeforeTarget
        }

        return recordedPoints.lastOrNull()?.bpm
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

    private fun clearExerciseCallback() {
        try {
            listenToFuture(
                future = exerciseClient.clearUpdateCallbackAsync(exerciseUpdateCallback),
                onSuccess = {},
                onFailure = {}
            )
        } catch (_: Exception) {
            // Ignore callback cleanup failure.
        }
    }

    private fun resetCurrentSession() {
        recoveryJob?.cancel()
        recoveryJob = null

        recordedPoints.clear()

        recordingState = RecordingState.IDLE
        exerciseStarted = false
        finishingExercise = false

        currentBpm = 0.0
        maxBpm = 0.0
        elapsedSeconds = 0.0

        workoutEndHr = 0.0
        hr60 = 0.0
        hr120 = 0.0

        recoveryElapsedSeconds = 0

        workoutStartMillis = 0L
        workoutEndMillis = 0L

        updateState {
            it.copy(
                recordingState = RecordingState.IDLE,
                currentBpm = 0.0,
                maxBpm = 0.0,
                elapsedSeconds = 0.0,
                workoutEndHr = 0.0,
                hr60 = 0.0,
                hr120 = 0.0,
                sampleCount = 0,
                recoveryElapsedSeconds = 0,
                statusText = "Ready",
                syncStatusText = "Sync: not attempted",
                pendingCount = sessionStore.unsyncedCount(),
                debugStatusText = statusSummary()
            )
        }
    }

    private fun publishUiState(statusText: String? = null) {
        updateState {
            it.copy(
                recordingState = recordingState,
                currentBpm = currentBpm,
                maxBpm = maxBpm,
                elapsedSeconds = elapsedSeconds,
                workoutEndHr = workoutEndHr,
                hr60 = hr60,
                hr120 = hr120,
                sampleCount = recordedPoints.size,
                pendingCount = sessionStore.unsyncedCount(),
                recoveryElapsedSeconds = recoveryElapsedSeconds,
                statusText = statusText ?: it.statusText,
                debugStatusText = statusSummary()
            )
        }
    }

    private fun updateState(
        reducer: (HrRecordingUiState) -> HrRecordingUiState
    ) {
        _uiState.value = reducer(_uiState.value)
    }

    private fun statusSummary(): String {
        val sessions = sessionStore.loadAllSessions()

        val pending = sessions.count { it.syncStatus == "PENDING" }
        val queued = sessions.count { it.syncStatus == "QUEUED" }
        val synced = sessions.count { it.syncStatus == "SYNCED" }

        return "Debug: Total ${sessions.size}, P $pending, Q $queued, S $synced"
    }

    private fun startForegroundRecording() {
        if (isForeground) {
            updateNotification()
            return
        }

        startForeground(
            NOTIFICATION_ID,
            buildNotification()
        )

        isForeground = true
    }

    private fun stopForegroundRecording() {
        if (!isForeground) {
            releaseWakeLock()
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        isForeground = false
        releaseWakeLock()
    }

    private fun updateNotification() {
        if (!isForeground) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        notificationManager.notify(
            NOTIFICATION_ID,
            buildNotification()
        )
    }

    private fun buildNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java)

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = when (recordingState) {
            RecordingState.WORKOUT -> "Recording workout"
            RecordingState.RECOVERY -> "Recording recovery"
            RecordingState.SAVED -> "Recovery saved"
            RecordingState.IDLE -> "Pulse Recovery"
        }

        val text = when (recordingState) {
            RecordingState.WORKOUT -> {
                "HR ${formatBpm(currentBpm)} • Workout ${formatSeconds(elapsedSeconds.toInt())}"
            }

            RecordingState.RECOVERY -> {
                "HR ${formatBpm(currentBpm)} • Recovery $recoveryElapsedSeconds/$RECOVERY_DURATION_SECONDS sec"
            }

            RecordingState.SAVED -> {
                "Session saved"
            }

            RecordingState.IDLE -> {
                "Ready"
            }
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_upload)
            .setContentIntent(pendingIntent)
            .setOngoing(
                recordingState == RecordingState.WORKOUT ||
                        recordingState == RecordingState.RECOVERY
            )
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val existingChannel =
            notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)

        if (existingChannel != null) {
            return
        }

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        )

        notificationManager.createNotificationChannel(channel)
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "PulseRecoveryWear:HrRecordingWakeLock"
        ).apply {
            setReferenceCounted(false)
            acquire(15 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {
            // Ignore release errors.
        }

        wakeLock = null
    }

    private fun stopServiceIfIdle() {
        if (recordingState == RecordingState.WORKOUT ||
            recordingState == RecordingState.RECOVERY
        ) {
            return
        }

        stopForegroundRecording()
        stopSelf()
    }

    private fun <T> listenToFuture(
        future: ListenableFuture<T>,
        onSuccess: (T?) -> Unit,
        onFailure: (Exception) -> Unit
    ) {
        future.addListener(
            {
                try {
                    onSuccess(future.get())
                } catch (e: Exception) {
                    onFailure(e)
                }
            },
            ContextCompat.getMainExecutor(this)
        )
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

        if (exerciseStarted) {
            try {
                exerciseClient.endExerciseAsync()
            } catch (_: Exception) {
                // Ignore cleanup failure during destroy.
            }
        }

        clearExerciseCallback()
        stopForegroundRecording()

        super.onDestroy()
    }
}