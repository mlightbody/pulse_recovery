package com.example.pulserecoverywear.sync

import android.util.Log
import com.example.pulserecoverywear.storage.HrSessionStore
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import java.nio.charset.StandardCharsets

class WatchAckReceiverService : WearableListenerService() {

    companion object {
        private const val TAG = "WatchAckReceiver"
        private const val HR_SESSION_ACK_PATH = "/hr_session_ack"
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)

        if (messageEvent.path != HR_SESSION_ACK_PATH) {
            return
        }

        val sessionId = String(messageEvent.data, StandardCharsets.UTF_8)

        if (sessionId.isBlank()) {
            Log.w(TAG, "Received ACK with blank sessionId")
            return
        }

        try {
            val store = HrSessionStore(this)
            store.markSessionSynced(sessionId)

            Log.i(TAG, "Marked session as SYNCED: $sessionId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to mark session as synced: $sessionId", e)
        }
    }
}