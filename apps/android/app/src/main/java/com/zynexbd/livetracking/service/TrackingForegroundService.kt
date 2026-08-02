package com.zynexbd.livetracking.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.zynexbd.livetracking.LiveTrackingApp
import com.zynexbd.livetracking.R
import com.zynexbd.livetracking.data.ApiClient
import com.zynexbd.livetracking.data.LocationUpdateRequest
import com.zynexbd.livetracking.ui.login.LoginActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Persistent foreground service started automatically after a successful
 * User (driver) login. Fetches the current location and POSTs it to the API
 * once every 60 seconds until the service is stopped (logout).
 *
 * A foreground service + persistent notification is required to keep
 * getting location updates reliably under Doze / App Standby / background
 * execution limits on Android 8+.
 */
class TrackingForegroundService : Service() {

    private val job = SupervisorJob()
    private val scope = CoroutineScope(job)
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var trackingJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification(), foregroundServiceType())

        if (trackingJob?.isActive != true) {
            trackingJob = scope.launch { trackingLoop() }
        }

        // Restart with last intent if the system kills the process.
        return START_STICKY
    }

    private suspend fun trackingLoop() {
        while (true) {
            val app = application as LiveTrackingApp
            if (!app.sessionManager.isLoggedIn) {
                stopSelf()
                return
            }

            try {
                val location = fetchCurrentLocation()
                if (location != null) {
                    val response = ApiClient.service.postLocation(
                        LocationUpdateRequest(location.latitude, location.longitude)
                    )
                    if (!response.isSuccessful) {
                        Log.w(TAG, "Location POST failed: HTTP ${response.code()}")
                    }
                } else {
                    Log.w(TAG, "No location available this cycle.")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending location update", e)
            }

            delay(TRACKING_INTERVAL_MS)
        }
    }

    private suspend fun fetchCurrentLocation() =
        try {
            val request = CurrentLocationRequest.Builder()
                .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                .setMaxUpdateAgeMillis(30_000)
                .build()
            fusedLocationClient.getCurrentLocation(request, null).await()
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing", e)
            null
        }

    private fun foregroundServiceType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0

    private fun buildNotification(): Notification {
        val openAppIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, LoginActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.tracking_notification_title))
            .setContentText(getString(R.string.tracking_notification_text))
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setContentIntent(openAppIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.tracking_channel_name),
            NotificationManager.IMPORTANCE_LOW
        )
        manager.createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "TrackingService"
        private const val CHANNEL_ID = "live_tracking_channel"
        private const val NOTIFICATION_ID = 1001
        private const val TRACKING_INTERVAL_MS = 60_000L

        fun start(context: android.content.Context) {
            val intent = Intent(context, TrackingForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: android.content.Context) {
            context.stopService(Intent(context, TrackingForegroundService::class.java))
        }
    }
}
