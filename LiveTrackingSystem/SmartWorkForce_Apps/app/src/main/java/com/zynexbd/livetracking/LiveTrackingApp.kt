package com.zynexbd.livetracking

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.zynexbd.livetracking.services.NotificationSyncWorker
import com.zynexbd.livetracking.utils.NotificationHelper

class LiveTrackingApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Force Light Mode so Dark Mode system settings do not alter the UI design
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)

        // Initialize high priority notification channel for heads-up alerts
        NotificationHelper.createNotificationChannel(this)

        // Initialize background notification sync worker
        NotificationSyncWorker.enqueuePeriodicSync(this)

        // Pre-warm Google Maps SDK Renderer in background so maps open instantly without lag
        Thread {
            try {
                com.google.android.gms.maps.MapsInitializer.initialize(
                    this,
                    com.google.android.gms.maps.MapsInitializer.Renderer.LATEST,
                    null
                )
            } catch (_: Exception) {}
        }.start()
    }
}
