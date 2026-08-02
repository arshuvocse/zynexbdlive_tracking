package com.zynexbd.livetracking.data

import com.zynexbd.livetracking.BuildConfig
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object ApiClient {

    /** Lazily (re)built whenever the session token changes; call [rebuild] after login/logout. */
    @Volatile
    private var retrofit: Retrofit? = null

    private var sessionManager: SessionManager? = null

    fun init(sessionManager: SessionManager) {
        this.sessionManager = sessionManager
        rebuild()
    }

    fun rebuild() {
        val authInterceptor = Interceptor { chain ->
            val token = sessionManager?.token
            val request = chain.request().newBuilder().apply {
                if (!token.isNullOrEmpty()) {
                    addHeader("Authorization", "Bearer $token")
                }
            }.build()
            chain.proceed(request)
        }

        val logging = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY else HttpLoggingInterceptor.Level.NONE
        }

        val client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .addInterceptor(authInterceptor)
            .addInterceptor(logging)
            .build()

        retrofit = Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    val service: ApiService
        get() = (retrofit ?: throw IllegalStateException("ApiClient.init() must be called first"))
            .create(ApiService::class.java)
}
