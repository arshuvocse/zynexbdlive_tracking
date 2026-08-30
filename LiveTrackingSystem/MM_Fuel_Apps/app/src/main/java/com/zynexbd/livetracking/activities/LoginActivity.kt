package com.zynexbd.livetracking.activities

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.zynexbd.livetracking.databinding.ActivityLoginBinding
import com.zynexbd.livetracking.utils.AppUpdateHelper
import com.zynexbd.livetracking.utils.SessionManager
import com.zynexbd.livetracking.viewmodel.LoginUiState
import com.zynexbd.livetracking.viewmodel.LoginViewModel

/**
 * Single entry point for both Admin and User roles. On success, routes by
 * role: Admin -> AdminDashboardActivity, User -> UserHomeActivity.
 * TrackingForegroundService is NOT started here - starting a "location" type
 * foreground service without location permission already granted crashes the
 * app (ForegroundServiceDidNotStartInTimeException / SecurityException), and
 * that failure can't be caught by the caller since it's thrown async by the
 * system. UserHomeActivity's mandatory permission+GPS gate starts the service
 * only once both are confirmed ready.
 */
class LoginActivity : BaseActivity() {

    private lateinit var binding: ActivityLoginBinding
    private lateinit var viewModel: LoginViewModel
    private lateinit var session: SessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        session = SessionManager(this)
        viewModel = ViewModelProvider(this)[LoginViewModel::class.java]

        // Check for App Updates
        AppUpdateHelper.checkForUpdate(this, lifecycleScope)

        if (session.isLoggedIn()) {
            routeByRole(session.getRole())
            return
        }

        val isEn = com.zynexbd.livetracking.utils.LanguageManager.getLanguage(this) == com.zynexbd.livetracking.utils.LanguageManager.LANG_EN
        binding.buttonLanguage.text = if (isEn) "🌐 English 🇬🇧" else "🌐 বাংলা 🇧🇩"
        binding.buttonLanguage.setOnClickListener {
            showLanguageSelectionDialog()
        }

        binding.layoutLoginFooter.setOnClickListener {
            try {
                val browserIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://zynexsofttech.com"))
                startActivity(browserIntent)
            } catch (e: Exception) {
            }
        }

        binding.buttonLogin.setOnClickListener {
            val username = binding.editUsername.text.toString().trim()
            val password = binding.editPassword.text.toString()
            viewModel.login(username, password)
        }

        viewModel.uiState.observe(this) { state ->
            when (state) {
                is LoginUiState.Idle -> {}
                is LoginUiState.Loading -> {
                    binding.buttonLogin.isEnabled = false
                    binding.buttonLogin.text = if (isEn) "Signing in..." else "লগইন হচ্ছে..."
                }
                is LoginUiState.Error -> {
                    binding.buttonLogin.isEnabled = true
                    binding.buttonLogin.text = if (isEn) "SIGN IN" else "লগইন করুন"
                    val msg = when {
                        state.message.contains("Invalid username or password", ignoreCase = true) -> if (isEn) "Invalid username or password." else "ইউজারনেম বা পাসওয়ার্ড সঠিক নয়।"
                        state.message.contains("Network", ignoreCase = true) || state.message.contains("Connection", ignoreCase = true) -> if (isEn) "Server connection failed. Check your network." else "সারভারে কানেক্ট করা যাচ্ছে না। নেটওয়ার্ক চেক করুন।"
                        else -> state.message
                    }
                    Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
                }
                is LoginUiState.Success -> {
                    binding.buttonLogin.isEnabled = true
                    binding.buttonLogin.text = if (isEn) "SIGN IN" else "লগইন করুন"
                    routeByRole(state.response.role)
                }
            }
        }
    }

    private fun routeByRole(role: String?) {
        when (role) {
            "Admin" -> {
                startActivity(Intent(this, AdminOverviewDashboardActivity::class.java))
                finish()
            }
            "User" -> {
                startActivity(Intent(this, UserHomeActivity::class.java))
                finish()
            }
            else -> Toast.makeText(this, "Unknown role.", Toast.LENGTH_SHORT).show()
        }
    }
}
