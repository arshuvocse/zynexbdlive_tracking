package com.zynexbd.livetracking.ui.admin

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.RadioGroup
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.zynexbd.livetracking.LiveTrackingApp
import com.zynexbd.livetracking.data.ApiClient
import com.zynexbd.livetracking.data.CreateUserRequest
import com.zynexbd.livetracking.data.SignalRClient
import com.zynexbd.livetracking.data.UserLocationResponse
import com.zynexbd.livetracking.databinding.ActivityAdminDashboardBinding
import com.zynexbd.livetracking.databinding.DialogCreateUserBinding
import com.zynexbd.livetracking.ui.login.LoginActivity
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Live map of all drivers plus a "create user" action. Locations arrive two
 * ways: an initial REST snapshot (GET /api/locations/active) to populate the
 * map immediately, then live pushes over SignalR as drivers report in. A
 * background poll loop is kept as a fallback in case the socket drops, and
 * also to re-evaluate the 3-minute offline threshold for markers that stop
 * updating.
 */
class AdminDashboardActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var binding: ActivityAdminDashboardBinding
    private var googleMap: GoogleMap? = null
    private var signalRClient: SignalRClient? = null

    // userId -> marker, so we update in place instead of re-adding.
    private val markers = mutableMapOf<Int, com.google.android.gms.maps.model.Marker>()
    private val lastKnownLocations = mutableMapOf<Int, UserLocationResponse>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAdminDashboardBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val mapFragment = supportFragmentManager.findFragmentById(com.zynexbd.livetracking.R.id.mapFragment) as SupportMapFragment
        mapFragment.getMapAsync(this)

        binding.addUserFab.setOnClickListener { showCreateUserDialog() }
        binding.logoutFab.setOnClickListener { logout() }

        loadActiveUsers()
        connectLiveUpdates()
        startPollingFallback()
    }

    override fun onMapReady(map: GoogleMap) {
        googleMap = map
        renderAllMarkers()
    }

    private fun loadActiveUsers() {
        lifecycleScope.launch {
            try {
                val response = ApiClient.service.getActiveUsers()
                if (response.isSuccessful) {
                    response.body()?.forEach { lastKnownLocations[it.userId] = it }
                    renderAllMarkers()
                }
            } catch (_: Exception) {
                // Non-fatal: SignalR and the poll loop will fill markers in as data arrives.
            }
        }
    }

    private fun connectLiveUpdates() {
        val token = (application as LiveTrackingApp).sessionManager.token ?: return
        val client = SignalRClient(token)
        client.connect(onLocationUpdate = { update ->
            runOnUiThread {
                lastKnownLocations[update.userId] = update
                upsertMarker(update)
            }
        })
        signalRClient = client
    }

    private fun startPollingFallback() {
        lifecycleScope.launch {
            while (true) {
                delay(60_000)
                loadActiveUsers()
            }
        }
    }

    private fun renderAllMarkers() {
        val map = googleMap ?: return
        lastKnownLocations.values.forEach { upsertMarker(it) }

        if (markers.isNotEmpty() && markers.size == lastKnownLocations.size) {
            val first = lastKnownLocations.values.first()
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(first.latitude, first.longitude), 12f))
        }
    }

    private fun upsertMarker(location: UserLocationResponse) {
        val map = googleMap ?: return
        val position = LatLng(location.latitude, location.longitude)
        val hue = if (location.isOnline) BitmapDescriptorFactory.HUE_GREEN else BitmapDescriptorFactory.HUE_RED
        val status = if (location.isOnline) "Online" else "Offline"

        val existing = markers[location.userId]
        if (existing != null) {
            existing.position = position
            existing.title = "${location.name} (${status})"
        } else {
            val marker = map.addMarker(
                MarkerOptions()
                    .position(position)
                    .title("${location.name} (${status})")
                    .icon(BitmapDescriptorFactory.defaultMarker(hue))
            )
            if (marker != null) markers[location.userId] = marker
        }
    }

    private fun showCreateUserDialog() {
        val dialogBinding = DialogCreateUserBinding.inflate(LayoutInflater.from(this))

        AlertDialog.Builder(this)
            .setTitle("Create User")
            .setView(dialogBinding.root)
            .setPositiveButton("Create") { _, _ ->
                val name = dialogBinding.nameInput.text?.toString()?.trim().orEmpty()
                val username = dialogBinding.usernameInput.text?.toString()?.trim().orEmpty()
                val password = dialogBinding.passwordInput.text?.toString().orEmpty()
                val role = if (dialogBinding.roleGroup.checkedRadioButtonId == dialogBinding.roleAdmin.id) "Admin" else "User"

                if (name.isEmpty() || username.isEmpty() || password.length < 6) {
                    android.widget.Toast.makeText(this, "Fill all fields; password needs 6+ characters.", android.widget.Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }

                createUser(name, username, password, role)
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun createUser(name: String, username: String, password: String, role: String) {
        lifecycleScope.launch {
            try {
                val response = ApiClient.service.createUser(CreateUserRequest(name, username, password, role))
                val message = if (response.isSuccessful) "User created." else "Failed: ${response.code()}"
                android.widget.Toast.makeText(this@AdminDashboardActivity, message, android.widget.Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                android.widget.Toast.makeText(this@AdminDashboardActivity, "Error: ${e.message}", android.widget.Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun logout() {
        signalRClient?.disconnect()
        (application as LiveTrackingApp).sessionManager.clear()
        startActivity(Intent(this, LoginActivity::class.java))
        finish()
    }

    override fun onDestroy() {
        signalRClient?.disconnect()
        super.onDestroy()
    }
}
