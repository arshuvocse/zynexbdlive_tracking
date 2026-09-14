package com.zynexbd.livetracking.activities

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import androidx.lifecycle.lifecycleScope
import com.zynexbd.livetracking.databinding.ActivitySplashBinding
import com.zynexbd.livetracking.utils.AppUpdateHelper
import com.zynexbd.livetracking.utils.SessionManager

@SuppressLint("CustomSplashScreen")
class SplashActivity : BaseActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val handler = Handler(Looper.getMainLooper())
    private var isNavigated = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Check for App Updates in background
        AppUpdateHelper.checkForUpdate(this, lifecycleScope)

        // Start entrance animations
        playEntranceAnimation()

        // Wait 1.6 seconds for smooth splash presentation, then route by session
        handler.postDelayed({
            navigateNext()
        }, 1600)
    }

    private fun playEntranceAnimation() {
        binding.layoutCenterBrand.alpha = 0f
        binding.layoutCenterBrand.scaleX = 0.88f
        binding.layoutCenterBrand.scaleY = 0.88f

        binding.layoutCenterBrand.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(750)
            .setInterpolator(DecelerateInterpolator())
            .start()

        binding.layoutSplashFooter.alpha = 0f
        binding.layoutSplashFooter.animate()
            .alpha(1f)
            .setDuration(900)
            .setStartDelay(300)
            .start()
    }

    private fun navigateNext() {
        if (isFinishing || isDestroyed || isNavigated) return
        isNavigated = true

        val session = SessionManager(this)
        val intent = if (session.isLoggedIn()) {
            when (session.getRole()) {
                "Admin" -> Intent(this, AdminOverviewDashboardActivity::class.java)
                else -> Intent(this, UserHomeActivity::class.java)
            }
        } else {
            Intent(this, LoginActivity::class.java)
        }

        startActivity(intent)
        @Suppress("DEPRECATION")
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
        finish()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
