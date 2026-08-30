package com.zynexbd.livetracking.models

import com.google.gson.annotations.SerializedName

data class LoginRequest(
    val username: String,
    val password: String,
    val deviceId: String? = null,
    val deviceModel: String? = null
)

data class LoginResponse(
    val token: String? = null,
    @SerializedName("expiresAt") val expiresAt: String? = null,
    val userId: Int = 0,
    @SerializedName(value = "name", alternate = ["fullName"]) val name: String? = null,
    val username: String? = null,
    val role: String? = null,
    @SerializedName("companyId") val companyId: Int? = null,
    @SerializedName("companyName") val companyName: String? = null,
    val data: LoginResponse? = null
)
