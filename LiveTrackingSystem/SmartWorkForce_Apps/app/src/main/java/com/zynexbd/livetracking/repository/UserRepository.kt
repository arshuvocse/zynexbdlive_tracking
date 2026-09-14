package com.zynexbd.livetracking.repository

import android.content.Context
import com.zynexbd.livetracking.models.*
import com.zynexbd.livetracking.network.ApiClient
import com.zynexbd.livetracking.utils.SessionManager
import com.zynexbd.livetracking.utils.safeApiCall

class UserRepository(context: Context) {

    private val api = ApiClient.getApiService(context)
    private val session = SessionManager(context)

    suspend fun getUsers(): Result<List<User>> = safeApiCall {
        val resp = api.getUsers(session.getCompanyId())
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load users (${resp.code()})")
    }

    suspend fun createUser(request: CreateUserRequest): Result<User> = safeApiCall {
        val resp = api.createUser(request)
        if (resp.isSuccessful) {
            resp.body() ?: error("Empty response")
        } else {
            val err = com.zynexbd.livetracking.utils.NetworkErrorHandler.parseHttpError(
                code = resp.code(),
                errorBody = resp.errorBody()?.string(),
                fallbackMessage = "ব্যবহারকারী তৈরি করতে ব্যর্থ হয়েছে (${resp.code()})"
            )
            error(err)
        }
    }

    suspend fun updateUser(id: Int, request: UpdateUserRequest): Result<User> = safeApiCall {
        val resp = api.updateUser(id, request)
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to update user (${resp.code()})")
    }

    suspend fun setActive(user: User, isActive: Boolean): Result<User> =
        updateUser(user.id, UpdateUserRequest(
            name = user.name,
            role = user.role,
            isActive = isActive,
            phoneNumber = user.phoneNumber,
            officeLocationId = user.officeLocationId,
            assignedOfficeLocationIds = user.assignedOfficeLocationIds
        ))

    suspend fun resetPassword(id: Int, newPassword: String): Result<Unit> = safeApiCall {
        val resp = api.resetPassword(id, ResetPasswordRequest(newPassword))
        if (!resp.isSuccessful) error("Failed to reset password (${resp.code()})")
    }

    suspend fun resetUserDevice(id: Int): Result<Unit> = safeApiCall {
        val resp = api.resetUserDevice(id)
        if (!resp.isSuccessful) error("Failed to reset device binding (${resp.code()})")
    }

    suspend fun getOfficeLocations(all: Boolean? = null): Result<List<OfficeLocation>> = safeApiCall {
        val resp = api.getOfficeLocations(all)
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load office locations (${resp.code()})")
    }

    suspend fun createOfficeLocation(request: CreateOfficeLocationRequest): Result<OfficeLocation> = safeApiCall {
        val resp = api.createOfficeLocation(request)
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to create office location (${resp.code()})")
    }

    suspend fun updateOfficeLocation(id: Int, request: UpdateOfficeLocationRequest): Result<OfficeLocation> = safeApiCall {
        val resp = api.updateOfficeLocation(id, request)
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to update office location (${resp.code()})")
    }

    suspend fun deleteOfficeLocation(id: Int): Result<Unit> = safeApiCall {
        val resp = api.deleteOfficeLocation(id)
        if (!resp.isSuccessful) error("Failed to delete office location (${resp.code()})")
    }

    suspend fun getUserQuota(): Result<AdminUserQuota> = safeApiCall {
        val resp = api.getUserQuota(session.getCompanyId())
        if (resp.isSuccessful) resp.body() ?: AdminUserQuota() else error("Failed to load user quota (${resp.code()})")
    }
}
