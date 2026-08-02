package com.zynexbd.livetracking.data

data class LoginRequest(
    val username: String,
    val password: String
)

data class LoginResponse(
    val token: String,
    val role: String,
    val userId: Int,
    val name: String,
    val expiresAt: String
)

data class LocationUpdateRequest(
    val latitude: Double,
    val longitude: Double
)

data class UserLocationResponse(
    val userId: Int,
    val name: String,
    val username: String,
    val latitude: Double,
    val longitude: Double,
    val recordedAt: String,
    val isOnline: Boolean
)

data class CreateUserRequest(
    val name: String,
    val username: String,
    val password: String,
    val role: String
)

data class UserResponse(
    val id: Int,
    val name: String,
    val username: String,
    val role: String,
    val isActive: Boolean,
    val createdAt: String
)
