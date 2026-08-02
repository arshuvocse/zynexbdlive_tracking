package com.zynexbd.livetracking.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.zynexbd.livetracking.LiveTrackingApp

/** Resumes tracking after a device reboot if a User was already logged in. */
class BootRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val app = context.applicationContext as LiveTrackingApp
        val session = app.sessionManager
        if (session.isLoggedIn && session.role == "User") {
            TrackingForegroundService.start(context)
        }
    }
}
