package com.zynexbd.livetracking

import android.app.Application
import com.zynexbd.livetracking.data.ApiClient
import com.zynexbd.livetracking.data.SessionManager

class LiveTrackingApp : Application() {

    lateinit var sessionManager: SessionManager
        private set

    override fun onCreate() {
        super.onCreate()
        sessionManager = SessionManager(this)
        ApiClient.init(sessionManager)
    }
}
