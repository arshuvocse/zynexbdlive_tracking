package com.zynexbd.livetracking.repository

import android.content.Context
import com.zynexbd.livetracking.models.LoginRequest
import com.zynexbd.livetracking.models.LoginResponse
import com.zynexbd.livetracking.network.ApiClient
import com.zynexbd.livetracking.utils.NetworkErrorHandler
import com.zynexbd.livetracking.utils.SessionManager

sealed class AuthResult {
    data class Success(val response: LoginResponse) : AuthResult()
    data class Error(val message: String) : AuthResult()
}

class AuthRepository(private val context: Context) {

    private val api = ApiClient.getApiService(context)
    private val session = SessionManager(context)

    suspend fun login(username: String, password: String, deviceId: String? = null, deviceModel: String? = null): AuthResult {
        return try {
            val resp = api.login(LoginRequest(username, password, deviceId, deviceModel))
            if (resp.isSuccessful) {
                val body = resp.body()
                val target = if (!body?.token.isNullOrEmpty()) body else body?.data
                val token = target?.token

                if (target != null && !token.isNullOrEmpty()) {
                    val role = target.role ?: body?.role ?: "User"
                    val userId = if (target.userId != 0) target.userId else body?.userId ?: 0
                    val uname = target.username ?: body?.username ?: username
                    val fullName = target.name ?: body?.name ?: uname
                    val companyId = target.companyId ?: body?.companyId
                    val companyName = target.companyName ?: body?.companyName

                    session.saveSession(
                        token = token,
                        role = role,
                        userId = userId,
                        username = uname,
                        fullName = fullName,
                        companyId = companyId,
                        companyName = companyName
                    )
                    AuthResult.Success(
                        LoginResponse(
                            token = token,
                            expiresAt = target.expiresAt ?: body?.expiresAt,
                            userId = userId,
                            name = fullName,
                            username = uname,
                            role = role,
                            companyId = companyId,
                            companyName = companyName
                        )
                    )
                } else {
                    AuthResult.Error("Invalid response format: token missing.")
                }
            } else if (resp.code() == 401) {
                AuthResult.Error("ইউজারনেম বা পাসওয়ার্ড সঠিক নয়।")
            } else {
                val rawBody = resp.errorBody()?.string()
                val friendlyMsg = NetworkErrorHandler.parseHttpError(
                    code = resp.code(),
                    errorBody = rawBody,
                    fallbackMessage = "লগইন সম্পন্ন করা যায়নি (${resp.code()})।"
                )
                AuthResult.Error(friendlyMsg)
            }
        } catch (e: Exception) {
            AuthResult.Error(NetworkErrorHandler.friendlyMessage(e))
        }
    }

    fun logout() {
        session.clear()
    }
}
