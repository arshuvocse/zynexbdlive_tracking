package com.zynexbd.livetracking.ui.user

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.zynexbd.livetracking.LiveTrackingApp
import com.zynexbd.livetracking.databinding.ActivityUserHomeBinding
import com.zynexbd.livetracking.service.PermissionHelper
import com.zynexbd.livetracking.service.TrackingForegroundService
import com.zynexbd.livetracking.ui.login.LoginActivity

/**
 * Landing screen for a logged-in Driver. No "Start Duty" toggle: tracking
 * starts automatically once the required permissions are granted.
 */
class UserHomeActivity : AppCompatActivity() {

    private lateinit var binding: ActivityUserHomeBinding

    private val requestPermissions = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { grants ->
        val fineGranted = grants[Manifest.permission.ACCESS_FINE_LOCATION] == true
        if (fineGranted) {
            requestBackgroundLocationIfNeeded()
        } else {
            binding.statusText.text = "Location permission is required to track your position."
        }
    }

    private val requestBackgroundPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { startTrackingAndPromptBatteryOptimization() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityUserHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val session = (application as LiveTrackingApp).sessionManager
        binding.welcomeText.text = "Welcome, ${session.userName ?: "Driver"}"

        binding.logoutButton.setOnClickListener { logout() }

        ensurePermissionsThenStartTracking()
    }

    private fun ensurePermissionsThenStartTracking() {
        val permissionsToRequest = mutableListOf<String>()

        if (!PermissionHelper.hasForegroundLocationPermission(this)) {
            permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
            permissionsToRequest.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        if (permissionsToRequest.isNotEmpty()) {
            requestPermissions.launch(permissionsToRequest.toTypedArray())
        } else {
            requestBackgroundLocationIfNeeded()
        }
    }

    private fun requestBackgroundLocationIfNeeded() {
        if (PermissionHelper.hasBackgroundLocationPermission(this)) {
            startTrackingAndPromptBatteryOptimization()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            requestBackgroundPermission.launch(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        } else {
            startTrackingAndPromptBatteryOptimization()
        }
    }

    private fun startTrackingAndPromptBatteryOptimization() {
        TrackingForegroundService.start(this)
        binding.statusText.text = "Location sharing is active."

        if (!PermissionHelper.isIgnoringBatteryOptimizations(this)) {
            AlertDialog.Builder(this)
                .setTitle("Disable Battery Optimization")
                .setMessage("To keep sending your location reliably in the background, please allow this app to run without battery restrictions.")
                .setPositiveButton("Allow") { _, _ ->
                    startActivity(PermissionHelper.requestIgnoreBatteryOptimizationsIntent(this))
                }
                .setNegativeButton("Not now", null)
                .show()
        }
    }

    private fun logout() {
        TrackingForegroundService.stop(this)
        (application as LiveTrackingApp).sessionManager.clear()
        startActivity(Intent(this, LoginActivity::class.java))
        finish()
    }
}
