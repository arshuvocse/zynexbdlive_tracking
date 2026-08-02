package com.zynexbd.livetracking.data

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path

interface ApiService {

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("api/locations")
    suspend fun postLocation(@Body request: LocationUpdateRequest): Response<Unit>

    @GET("api/locations/active")
    suspend fun getActiveUsers(): Response<List<UserLocationResponse>>

    @GET("api/users")
    suspend fun getUsers(): Response<List<UserResponse>>

    @POST("api/users")
    suspend fun createUser(@Body request: CreateUserRequest): Response<UserResponse>

    @PUT("api/users/{id}/deactivate")
    suspend fun deactivateUser(@Path("id") id: Int): Response<Unit>
}
