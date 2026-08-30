package com.zynexbd.livetracking.utils

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import com.zynexbd.livetracking.services.TrackingForegroundService

/**
 * Stores JWT + role + user info after login so the app can restore
 * session state (e.g. on boot, when the foreground service restarts).
 */
class SessionManager(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(Constants.PREFS_NAME, Context.MODE_PRIVATE)

    fun saveSession(
        token: String,
        role: String,
        userId: Int,
        username: String,
        fullName: String,
        companyId: Int? = null,
        companyName: String? = null
    ) {
        val editor = prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_ROLE, role)
            .putInt(KEY_USER_ID, userId)
            .putString(KEY_USERNAME, username)
            .putString(KEY_FULL_NAME, fullName)

        if (companyId != null && companyId > 0) {
            editor.putInt(KEY_COMPANY_ID, companyId)
        } else {
            editor.remove(KEY_COMPANY_ID)
        }

        if (!companyName.isNullOrBlank()) {
            editor.putString(KEY_COMPANY_NAME, companyName)
        } else {
            editor.remove(KEY_COMPANY_NAME)
        }

        editor.apply()
    }

    fun getToken(): String? = prefs.getString(KEY_TOKEN, null)
    fun getRole(): String? = prefs.getString(KEY_ROLE, null)
    fun getUserId(): Int = prefs.getInt(KEY_USER_ID, -1)
    fun getUsername(): String? = prefs.getString(KEY_USERNAME, null)
    fun getFullName(): String? = prefs.getString(KEY_FULL_NAME, null)
    fun getCompanyId(): Int? = if (prefs.contains(KEY_COMPANY_ID)) prefs.getInt(KEY_COMPANY_ID, 0) else null
    fun getCompanyName(): String? = prefs.getString(KEY_COMPANY_NAME, null)

    fun isLoggedIn(): Boolean = !getToken().isNullOrEmpty()

    fun isUser(): Boolean {
        val role = getRole() ?: return false
        return role.equals("User", ignoreCase = true) || role.equals("Employee", ignoreCase = true) || role.equals("Officer", ignoreCase = true) || !role.equals("Admin", ignoreCase = true)
    }
    fun isAdmin(): Boolean = getRole()?.equals("Admin", ignoreCase = true) == true

    fun clear() {
        prefs.edit().clear().apply()
    }

    fun logout(context: Context) {
        clear()
        try {
            val serviceIntent = Intent(context, TrackingForegroundService::class.java)
            context.stopService(serviceIntent)
        } catch (_: Exception) {}
    }

    companion object {
        private const val KEY_TOKEN = "token"
        private const val KEY_ROLE = "role"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USERNAME = "username"
        private const val KEY_FULL_NAME = "full_name"
        private const val KEY_COMPANY_ID = "company_id"
        private const val KEY_COMPANY_NAME = "company_name"
    }
}
