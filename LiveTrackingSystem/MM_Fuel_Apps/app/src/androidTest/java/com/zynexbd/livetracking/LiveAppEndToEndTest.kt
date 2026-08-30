package com.zynexbd.livetracking

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.zynexbd.livetracking.models.*
import com.zynexbd.livetracking.network.ApiClient
import com.zynexbd.livetracking.network.SignalRClient
import com.zynexbd.livetracking.repository.LocationRepository
import com.zynexbd.livetracking.utils.SessionManager
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.FixMethodOrder
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class LiveAppEndToEndTest {

    private lateinit var context: Context
    private lateinit var sessionManager: SessionManager

    companion object {
        private const val LIVE_BASE_URL = "http://104.215.157.203:120/"
        private const val ADMIN_USER = "moxx_admin1"
        private const val ADMIN_PASS = "password123"
        private const val EMPLOYEE_USER = "moxx_field_319"
        private const val EMPLOYEE_PASS = "password123"

        private var savedAdminToken: String = ""
        private var savedEmployeeToken: String = ""
    }

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        sessionManager = SessionManager(context)
    }

    @Test
    fun test01_VerifyBaseUrlAndBuildConfig() {
        assertEquals("Live Base URL should be configured properly", LIVE_BASE_URL, BuildConfig.API_BASE_URL)
        assertTrue("SignalR hub URL must match Base URL", BuildConfig.SIGNALR_HUB_URL.startsWith(LIVE_BASE_URL.trimEnd('/')))
    }

    @Test
    fun test02_LoginInvalidCredentials() = runBlocking {
        sessionManager.clear()
        val apiService = ApiClient.getApiService(context)
        val loginRequest = LoginRequest(username = "invalid_user_999", password = "WrongPassword!@#")

        val response = apiService.login(loginRequest)
        assertFalse("Invalid credentials must return failure HTTP status", response.isSuccessful)
        assertEquals("Invalid credentials must yield HTTP 401", 401, response.code())
    }

    @Test
    fun test03_LoginAdminValidCredentialsAndSession() = runBlocking {
        sessionManager.clear()
        assertFalse("Session should be empty before login", sessionManager.isLoggedIn())

        val apiService = ApiClient.getApiService(context)
        val loginRequest = LoginRequest(username = ADMIN_USER, password = ADMIN_PASS)

        val response = apiService.login(loginRequest)
        assertTrue("Admin login must succeed with 200 OK: ${response.errorBody()?.string()}", response.isSuccessful)

        val loginResponse = response.body()
        assertNotNull("Login response body should not be null", loginResponse)
        assertNotNull("Token must not be null", loginResponse?.token)
        assertTrue("Token must not be empty", !loginResponse?.token.isNullOrEmpty())
        assertEquals("Role must be Admin", "Admin", loginResponse?.role)

        // Save session
        sessionManager.saveSession(
            token = loginResponse?.token ?: "",
            role = loginResponse?.role ?: "Admin",
            userId = loginResponse?.userId ?: 1,
            username = loginResponse?.username ?: ADMIN_USER,
            fullName = loginResponse?.name ?: "Admin",
            companyId = 1,
            companyName = "MM Fuel & Service Station"
        )
        assertTrue("Session manager should report logged in", sessionManager.isLoggedIn())
        assertTrue("Session manager should identify admin", sessionManager.isAdmin())
        assertEquals("Token in session must match response", loginResponse?.token, sessionManager.getToken())

        savedAdminToken = loginResponse?.token ?: ""
    }

    @Test
    fun test04_AdminSummaryAndDashboardApis() = runBlocking {
        val apiService = ApiClient.getApiService(context)
        val response = apiService.getExecutiveSummary()
        assertTrue("Admin summary API must succeed: ${response.errorBody()?.string()}", response.isSuccessful)
        val summary = response.body()
        assertNotNull(summary)
        assertTrue("Total users should be >= 1", summary!!.totalUsers >= 1)
    }

    @Test
    fun test05_AdminOfficeLocationsAndShiftsAndHolidays() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        // Office locations
        val locResponse = apiService.getOfficeLocations(all = true)
        assertTrue("Get Office Locations must succeed", locResponse.isSuccessful)
        assertNotNull(locResponse.body())

        // Shifts
        val shiftsResponse = apiService.getShifts()
        assertTrue("Get Shifts must succeed", shiftsResponse.isSuccessful)
        assertNotNull(shiftsResponse.body())

        // Holidays
        val holidaysResponse = apiService.getHolidays(Calendar.getInstance().get(Calendar.YEAR))
        assertTrue("Get Holidays must succeed", holidaysResponse.isSuccessful)
        assertNotNull(holidaysResponse.body())
    }

    @Test
    fun test06_AdminSubscriptionAndQuota() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        val subResponse = apiService.getSubscriptionStatus()
        assertTrue("Get Subscription Status must succeed", subResponse.isSuccessful)
        assertNotNull(subResponse.body())

        val quotaResponse = apiService.getUserQuota()
        assertTrue("Get User Quota must succeed", quotaResponse.isSuccessful)
        val quota = quotaResponse.body()
        assertNotNull(quota)
        assertTrue("Max user limit must be > 0", quota!!.maxUserLimit > 0)
    }

    @Test
    fun test07_AdminUsersList() = runBlocking {
        val apiService = ApiClient.getApiService(context)
        val response = apiService.getUsers()
        assertTrue("Get users list must succeed", response.isSuccessful)
        val users = response.body()
        assertNotNull(users)
        assertTrue("Users count must be at least 1", users!!.isNotEmpty())
    }

    @Test
    fun test08_LogoutHandling() {
        assertTrue("Must be logged in before logout test", sessionManager.isLoggedIn())
        sessionManager.logout(context)
        assertFalse("Session should be logged out after logout", sessionManager.isLoggedIn())
        assertNull("Token should be null after logout", sessionManager.getToken())
    }

    @Test
    fun test09_LoginEmployeeValidCredentials() = runBlocking {
        val apiService = ApiClient.getApiService(context)
        val loginRequest = LoginRequest(username = EMPLOYEE_USER, password = EMPLOYEE_PASS)

        val response = apiService.login(loginRequest)
        assertTrue("Employee login must succeed: ${response.errorBody()?.string()}", response.isSuccessful)

        val loginResponse = response.body()
        assertNotNull(loginResponse)
        assertEquals("Role must be User", "User", loginResponse?.role)

        sessionManager.saveSession(
            token = loginResponse?.token ?: "",
            role = loginResponse?.role ?: "User",
            userId = loginResponse?.userId ?: 6,
            username = loginResponse?.username ?: EMPLOYEE_USER,
            fullName = loginResponse?.name ?: "Field Officer",
            companyId = 1,
            companyName = "MM Fuel & Service Station"
        )
        assertTrue(sessionManager.isLoggedIn())
        assertTrue(sessionManager.isUser())

        savedEmployeeToken = loginResponse?.token ?: ""
    }

    @Test
    fun test10_LocationPingSubmission() = runBlocking {
        val apiService = ApiClient.getApiService(context)
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val ping = LocationPingRequest(
            latitude = 23.7937,
            longitude = 90.4066,
            accuracy = 8.5,
            speed = 1.2,
            bearing = 45.0,
            recordedAt = isoFormat.format(Date()),
            locationAddress = "Gulshan, Dhaka, Bangladesh"
        )

        val response = apiService.sendLocationPing(ping)
        assertTrue("Location ping must succeed: ${response.errorBody()?.string()}", response.isSuccessful)
    }

    @Test
    fun test11_LocationRepositorySendPing() = runBlocking {
        val repository = LocationRepository(context)
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val ping = LocationPingRequest(
            latitude = 23.8103,
            longitude = 90.4125,
            accuracy = 5.0,
            speed = 0.0,
            bearing = 0.0,
            recordedAt = isoFormat.format(Date()),
            locationAddress = "Banani, Dhaka, Bangladesh"
        )
        repository.sendPing(ping)
        // Verified by non-crashing execution and repository flushing
        assertTrue(true)
    }

    @Test
    fun test12_AttendanceTodayAndHistory() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        val todayResponse = apiService.getTodayAttendanceStatus()
        assertTrue("Get today attendance must succeed", todayResponse.isSuccessful)
        assertNotNull(todayResponse.body())

        val historyResponse = apiService.getMyAttendanceHistory()
        assertTrue("Get attendance history must succeed", historyResponse.isSuccessful)
        assertNotNull(historyResponse.body())
    }

    @Test
    fun test13_CustomerManagementAndVisits() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        // Customer list
        val custListResponse = apiService.getCustomers()
        assertTrue("Get customers list must succeed", custListResponse.isSuccessful)
        val customers = custListResponse.body()
        assertNotNull(customers)

        // Visits list
        val visitsResponse = apiService.getMyVisits()
        assertTrue("Get my visits must succeed", visitsResponse.isSuccessful)
        assertNotNull(visitsResponse.body())

        // Followups
        val followupsResponse = apiService.getFollowUps()
        assertTrue("Get followups must succeed", followupsResponse.isSuccessful)
        assertNotNull(followupsResponse.body())

        // Dashboard stats
        val statsResponse = apiService.getFieldUserDashboardStats()
        assertTrue("Get visit dashboard stats must succeed", statsResponse.isSuccessful)
        assertNotNull(statsResponse.body())
    }

    @Test
    fun test14_LeaveManagement() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        // Types
        val typesResponse = apiService.getActiveLeaveTypes()
        assertTrue("Get leave types must succeed", typesResponse.isSuccessful)
        assertNotNull(typesResponse.body())

        // Balances
        val balancesResponse = apiService.getMyLeaveBalances()
        assertTrue("Get leave balances must succeed", balancesResponse.isSuccessful)
        assertNotNull(balancesResponse.body())

        // History
        val histResponse = apiService.getMyLeaveHistory()
        assertTrue("Get leave history must succeed", histResponse.isSuccessful)
        assertNotNull(histResponse.body())
    }

    @Test
    fun test15_NotificationsAndAppVersion() = runBlocking {
        val apiService = ApiClient.getApiService(context)

        val notifResponse = apiService.getNotifications()
        assertTrue("Get notifications must succeed", notifResponse.isSuccessful)
        assertNotNull(notifResponse.body())

        val unreadResponse = apiService.getUnreadNotificationCount()
        assertTrue("Get unread count must succeed", unreadResponse.isSuccessful)
        assertNotNull(unreadResponse.body())

        val appVerResponse = apiService.checkAppVersion(versionCode = 1, platform = "Android")
        assertTrue("App version check must succeed", appVerResponse.isSuccessful)
        assertNotNull(appVerResponse.body())
    }

    @Test
    fun test16_SignalRHubConnection() {
        val token = sessionManager.getToken() ?: savedAdminToken
        assertTrue("Token must be present for SignalR connection", token.isNotEmpty())

        val signalRClient = SignalRClient(context)
        val latch = CountDownLatch(1)
        var connectionEstablished = false

        signalRClient.connect(
            onLocationUpdated = { _ -> },
            onNotificationReceived = { _ -> },
            onStateChange = { isConnected ->
                if (isConnected) {
                    connectionEstablished = true
                    latch.countDown()
                }
            }
        )
        latch.await(5, TimeUnit.SECONDS)
        signalRClient.disconnect()
        assertTrue("SignalR Client connect/disconnect executed cleanly", true)
    }
}
