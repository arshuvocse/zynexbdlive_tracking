package com.zynexbd.livetracking.models

data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T?,
    val errors: List<String>?
)
