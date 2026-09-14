package com.zynexbd.livetracking.repository

import android.content.Context
import com.zynexbd.livetracking.models.*
import com.zynexbd.livetracking.network.ApiClient
import com.zynexbd.livetracking.utils.safeApiCall

class LeaveRepository(context: Context) {

    private val api = ApiClient.getApiService(context)

    suspend fun getActiveTypes(): Result<List<LeaveType>> = safeApiCall {
        val resp = api.getActiveLeaveTypes()
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load leave types (${resp.code()})")
    }

    suspend fun getMyBalances(): Result<List<LeaveBalance>> = safeApiCall {
        val resp = api.getMyLeaveBalances()
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load balances (${resp.code()})")
    }

    suspend fun apply(request: ApplyLeaveRequest): Result<LeaveApplicationResponse> = safeApiCall {
        val resp = api.applyLeave(request)
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to apply for leave (${resp.code()})")
    }

    suspend fun getMyHistory(): Result<List<LeaveApplicationResponse>> = safeApiCall {
        val resp = api.getMyLeaveHistory()
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load leave history (${resp.code()})")
    }

    suspend fun cancel(id: Int): Result<LeaveApplicationResponse> = safeApiCall {
        val resp = api.cancelLeave(id)
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to cancel (${resp.code()})")
    }

    suspend fun getApplications(status: String? = null): Result<List<LeaveApplicationResponse>> = safeApiCall {
        val resp = api.getLeaveApplications(status)
        if (resp.isSuccessful) resp.body() ?: emptyList() else error("Failed to load applications (${resp.code()})")
    }

    suspend fun approve(id: Int, comment: String?): Result<LeaveApplicationResponse> = safeApiCall {
        val resp = api.approveLeave(id, LeaveReviewRequest(comment))
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to approve (${resp.code()})")
    }

    suspend fun reject(id: Int, comment: String?): Result<LeaveApplicationResponse> = safeApiCall {
        val resp = api.rejectLeave(id, LeaveReviewRequest(comment))
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed to reject (${resp.code()})")
    }

    suspend fun bulkApprove(ids: List<Int>, comment: String?): Result<BulkLeaveResponse> = safeApiCall {
        val resp = api.bulkApproveLeave(BulkLeaveRequest(ids, comment))
        if (resp.isSuccessful) resp.body() ?: error("Empty response") else error("Failed bulk approval (${resp.code()})")
    }
}
