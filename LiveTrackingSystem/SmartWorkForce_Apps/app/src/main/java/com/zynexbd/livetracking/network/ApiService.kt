package com.zynexbd.livetracking.network

import com.zynexbd.livetracking.models.*
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    @POST("api/auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @GET("api/subscription/status")
    suspend fun getSubscriptionStatus(): Response<SubscriptionStatus>

    @GET("api/subscription/plans")
    suspend fun getSubscriptionPlans(): Response<List<SubscriptionPlan>>

    @GET("api/subscription/user/{userId}/status")
    suspend fun getUserSubscriptionStatus(@Path("userId") userId: Int): Response<SubscriptionStatus>

    @POST("api/subscription/update-due-date")
    suspend fun updateSubscriptionDueDate(@Body request: UpdatePaymentDueDateRequest): Response<SubscriptionStatus>

    @GET("api/users")
    suspend fun getUsers(@Query("companyId") companyId: Int? = null): Response<List<User>>

    @GET("api/users/quota")
    suspend fun getUserQuota(@Query("companyId") companyId: Int? = null): Response<AdminUserQuota>

    @POST("api/users")
    suspend fun createUser(@Body request: CreateUserRequest): Response<User>

    @PUT("api/users/{id}")
    suspend fun updateUser(@Path("id") id: Int, @Body request: UpdateUserRequest): Response<User>

    @DELETE("api/users/{id}")
    suspend fun disableUser(@Path("id") id: Int): Response<Unit>

    @POST("api/users/{id}/reset-password")
    suspend fun resetPassword(@Path("id") id: Int, @Body request: ResetPasswordRequest): Response<Unit>

    @POST("api/users/{id}/reset-device")
    suspend fun resetUserDevice(@Path("id") id: Int): Response<Unit>

    @POST("api/locations/ping")
    suspend fun sendLocationPing(@Body request: LocationPingRequest): Response<Unit>

    @GET("api/locations/latest")
    suspend fun getLatestLocations(@Query("companyId") companyId: Int? = null): Response<List<LocationResponse>>

    @GET("api/locations/history/{userId}")
    suspend fun getRouteHistory(
        @Path("userId") userId: Int,
        @Query("date") date: String
    ): Response<List<LocationResponse>>

    @GET("api/admin/office-locations")
    suspend fun getOfficeLocations(@Query("all") all: Boolean? = null): Response<List<OfficeLocation>>

    @POST("api/admin/office-locations")
    suspend fun createOfficeLocation(@Body request: CreateOfficeLocationRequest): Response<OfficeLocation>

    @PUT("api/admin/office-locations/{id}")
    suspend fun updateOfficeLocation(@Path("id") id: Int, @Body request: UpdateOfficeLocationRequest): Response<OfficeLocation>

    @DELETE("api/admin/office-locations/{id}")
    suspend fun deleteOfficeLocation(@Path("id") id: Int): Response<Unit>

    @GET("api/admin/summary")
    suspend fun getExecutiveSummary(): Response<ExecutiveSummaryResponse>

    // Attendance
    @Multipart
    @POST("api/attendance/punch-in")
    suspend fun punchIn(
        @Part selfie: MultipartBody.Part,
        @Part("Latitude") latitude: RequestBody,
        @Part("Longitude") longitude: RequestBody
    ): Response<AttendanceResponse>

    @Multipart
    @POST("api/attendance/punch-out")
    suspend fun punchOut(
        @Part selfie: MultipartBody.Part,
        @Part("Latitude") latitude: RequestBody,
        @Part("Longitude") longitude: RequestBody
    ): Response<AttendanceResponse>

    @GET("api/attendance/today")
    suspend fun getTodayAttendanceStatus(): Response<TodayAttendanceStatusResponse>

    @GET("api/attendance/history")
    suspend fun getMyAttendanceHistory(
        @Query("month") month: Int? = null,
        @Query("year") year: Int? = null,
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<List<AttendanceResponse>>

    @GET("api/attendance/admin")
    suspend fun getAllAttendance(
        @Query("userId") userId: Int? = null,
        @Query("month") month: Int? = null,
        @Query("year") year: Int? = null,
        @Query("from") from: String? = null,
        @Query("to") to: String? = null
    ): Response<List<AttendanceResponse>>

    @GET("api/attendance/admin/monthly-summary")
    suspend fun getMonthlyAttendanceSummary(
        @Query("year") year: Int? = null,
        @Query("month") month: Int? = null,
        @Query("userId") userId: Int? = null
    ): Response<List<EmployeeMonthlyAttendanceSummary>>

    // Leave
    @GET("api/leave/types")
    suspend fun getActiveLeaveTypes(): Response<List<LeaveType>>

    @GET("api/leave/my-balances")
    suspend fun getMyLeaveBalances(): Response<List<LeaveBalance>>

    @POST("api/leave/apply")
    suspend fun applyLeave(@Body request: ApplyLeaveRequest): Response<LeaveApplicationResponse>

    @GET("api/leave/my-history")
    suspend fun getMyLeaveHistory(): Response<List<LeaveApplicationResponse>>

    @PUT("api/leave/{id}/cancel")
    suspend fun cancelLeave(@Path("id") id: Int): Response<LeaveApplicationResponse>

    @GET("api/leave/admin")
    suspend fun getLeaveApplications(@Query("status") status: String? = null): Response<List<LeaveApplicationResponse>>

    @PUT("api/leave/admin/{id}/approve")
    suspend fun approveLeave(@Path("id") id: Int, @Body request: LeaveReviewRequest): Response<LeaveApplicationResponse>

    @PUT("api/leave/admin/{id}/reject")
    suspend fun rejectLeave(@Path("id") id: Int, @Body request: LeaveReviewRequest): Response<LeaveApplicationResponse>

    @PUT("api/leave/admin/bulk-approve")
    suspend fun bulkApproveLeave(@Body request: BulkLeaveRequest): Response<BulkLeaveResponse>

    @GET("api/customers")
    suspend fun getCustomers(
        @Query("search") search: String? = null,
        @Query("targetUserId") targetUserId: Int? = null
    ): Response<List<Customer>>

    @GET("api/customers/{id}")
    suspend fun getCustomerById(@Path("id") id: Int): Response<Customer>

    @POST("api/customers")
    suspend fun createCustomer(@Body request: CreateCustomerRequest): Response<Customer>

    @POST("api/visits")
    suspend fun recordVisit(@Body request: RecordVisitRequest): Response<CustomerVisit>

    @GET("api/visits/my-visits")
    suspend fun getMyVisits(
        @Query("customerId") customerId: Int? = null,
        @Query("targetUserId") targetUserId: Int? = null
    ): Response<List<CustomerVisit>>

    @GET("api/visits/followups")
    suspend fun getFollowUps(
        @Query("category") category: String? = null,
        @Query("targetUserId") targetUserId: Int? = null
    ): Response<List<FollowUpItem>>

    @PUT("api/visits/{id}/complete-followup")
    suspend fun completeFollowUp(@Path("id") id: Long): Response<Unit>

    @GET("api/visits/dashboard-stats")
    suspend fun getFieldUserDashboardStats(): Response<FieldUserDashboardStats>

    // Shifts Management
    @GET("api/shifts")
    suspend fun getShifts(): Response<List<com.zynexbd.livetracking.models.Shift>>

    @POST("api/shifts")
    suspend fun createShift(@Body request: com.zynexbd.livetracking.models.CreateShiftRequest): Response<com.zynexbd.livetracking.models.Shift>

    @PUT("api/shifts/{id}")
    suspend fun updateShift(@Path("id") id: Int, @Body request: com.zynexbd.livetracking.models.UpdateShiftRequest): Response<com.zynexbd.livetracking.models.Shift>

    @PUT("api/shifts/{id}/set-default")
    suspend fun setDefaultShift(@Path("id") id: Int): Response<com.zynexbd.livetracking.models.Shift>

    @DELETE("api/shifts/{id}")
    suspend fun deleteShift(@Path("id") id: Int): Response<Unit>

    @GET("api/app-version/check")
    suspend fun checkAppVersion(
        @Query("versionCode") versionCode: Int,
        @Query("platform") platform: String = "Android",
        @Query("companyId") companyId: Int? = null
    ): Response<AppVersionCheckResponse>

    @GET("api/app-version/latest")
    suspend fun getLatestAppVersion(
        @Query("platform") platform: String = "Android",
        @Query("companyId") companyId: Int? = null
    ): Response<AppVersionDetails>

    @GET("api/notifications")
    suspend fun getNotifications(
        @Query("unreadOnly") unreadOnly: Boolean = false,
        @Query("take") take: Int = 50,
        @Query("companyId") companyId: Int? = null
    ): Response<List<NotificationItem>>

    @GET("api/notifications/unread-count")
    suspend fun getUnreadNotificationCount(
        @Query("companyId") companyId: Int? = null
    ): Response<UnreadNotificationCount>

    @PUT("api/notifications/{id}/read")
    suspend fun markNotificationAsRead(@Path("id") id: Int): Response<Unit>

    @PUT("api/notifications/mark-all-read")
    suspend fun markAllNotificationsAsRead(): Response<Unit>

    @POST("api/notifications/broadcast")
    suspend fun sendBroadcastNotification(@Body request: SendNotificationRequest): Response<NotificationItem>

    @POST("api/users/{id}/force-logout")
    suspend fun forceLogoutUser(@Path("id") id: Int): Response<Unit>

    @GET("api/admin/reports/employee-performance")
    suspend fun getEmployeePerformanceReport(
        @Query("year") year: Int? = null,
        @Query("month") month: Int? = null,
        @Query("userId") userId: Int? = null
    ): Response<MonthlyPerformanceReportResponse>

    // Holidays
    @GET("api/holidays")
    suspend fun getHolidays(
        @Query("year") year: Int? = null,
        @Query("month") month: Int? = null,
        @Query("includeInactive") includeInactive: Boolean = true
    ): Response<List<com.zynexbd.livetracking.models.Holiday>>

    @POST("api/holidays")
    suspend fun createHoliday(
        @Body request: com.zynexbd.livetracking.models.CreateOrUpdateHolidayRequest
    ): Response<com.zynexbd.livetracking.models.Holiday>

    @PUT("api/holidays/{id}")
    suspend fun updateHoliday(
        @Path("id") id: Int,
        @Body request: com.zynexbd.livetracking.models.CreateOrUpdateHolidayRequest
    ): Response<com.zynexbd.livetracking.models.Holiday>

    @PATCH("api/holidays/{id}/toggle-status")
    suspend fun toggleHolidayStatus(
        @Path("id") id: Int
    ): Response<com.zynexbd.livetracking.models.Holiday>

    @DELETE("api/holidays/{id}")
    suspend fun deleteHoliday(
        @Path("id") id: Int
    ): Response<Unit>
}
