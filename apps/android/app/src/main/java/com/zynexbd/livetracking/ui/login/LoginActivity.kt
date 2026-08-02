package com.zynexbd.livetracking.ui.login

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.zynexbd.livetracking.LiveTrackingApp
import com.zynexbd.livetracking.data.ApiClient
import com.zynexbd.livetracking.data.LoginRequest
import com.zynexbd.livetracking.databinding.ActivityLoginBinding
import com.zynexbd.livetracking.ui.admin.AdminDashboardActivity
import com.zynexbd.livetracking.ui.user.UserHomeActivity
import kotlinx.coroutines.launch
import java.io.IOException

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val app = application as LiveTrackingApp

        // Already logged in? Skip straight to the right screen.
        if (app.sessionManager.isLoggedIn) {
            routeToRoleHome(app.sessionManager.role)
            return
        }

        binding.loginButton.setOnClickListener {
            val username = binding.usernameInput.text?.toString()?.trim().orEmpty()
            val password = binding.passwordInput.text?.toString().orEmpty()

            if (username.isEmpty() || password.isEmpty()) {
                binding.errorText.text = "Please enter username and password."
                return@setOnClickListener
            }

            performLogin(username, password)
        }
    }

    private fun performLogin(username: String, password: String) {
        setLoading(true)
        lifecycleScope.launch {
            try {
                val response = ApiClient.service.login(LoginRequest(username, password))

                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    val app = application as LiveTrackingApp
                    app.sessionManager.saveSession(body)
                    ApiClient.rebuild()
                    routeToRoleHome(body.role)
                } else {
                    binding.errorText.text = "Invalid username or password."
                }
            } catch (e: IOException) {
                binding.errorText.text = "Cannot reach server. Check your network."
            } catch (e: Exception) {
                binding.errorText.text = "Login failed: ${e.message}"
            } finally {
                setLoading(false)
            }
        }
    }

    private fun routeToRoleHome(role: String?) {
        val intent = if (role == "Admin") {
            Intent(this, AdminDashboardActivity::class.java)
        } else {
            Intent(this, UserHomeActivity::class.java)
        }
        startActivity(intent)
        finish()
    }

    private fun setLoading(loading: Boolean) {
        binding.loginProgress.visibility = if (loading) android.view.View.VISIBLE else android.view.View.GONE
        binding.loginButton.isEnabled = !loading
        if (loading) binding.errorText.text = ""
    }
}
