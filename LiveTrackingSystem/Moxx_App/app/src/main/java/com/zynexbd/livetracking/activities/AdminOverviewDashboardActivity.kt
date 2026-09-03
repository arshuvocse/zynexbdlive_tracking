package com.zynexbd.livetracking.activities

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.core.view.GravityCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.zynexbd.livetracking.R
import com.zynexbd.livetracking.adapters.AttentionAdapter
import com.zynexbd.livetracking.adapters.DashboardActivityAdapter
import com.zynexbd.livetracking.adapters.DashboardActivityItem
import com.zynexbd.livetracking.databinding.ActivityAdminOverviewDashboardBinding
import com.zynexbd.livetracking.models.AttentionItem
import com.zynexbd.livetracking.models.FollowUpItem
import com.zynexbd.livetracking.models.CustomerVisit
import com.zynexbd.livetracking.network.ApiClient
import com.zynexbd.livetracking.network.RetrofitClient
import com.zynexbd.livetracking.utils.LanguageManager
import com.zynexbd.livetracking.utils.PaymentExpiredDialog
import com.zynexbd.livetracking.utils.SessionManager
import com.zynexbd.livetracking.viewmodel.UserManagementViewModel
import com.zynexbd.livetracking.views.BarChartView
import com.zynexbd.livetracking.views.DonutChartView
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Main Entry Dashboard for Admin (Executive Command Center):
 * Displays real-time KPIs, Visual Donut & Bar Charts, Quick Action Hub, Leaderboard, Attention Alerts, and Live Activity Stream.
 */
class AdminOverviewDashboardActivity : BaseActivity() {

    private lateinit var binding: ActivityAdminOverviewDashboardBinding
    private lateinit var viewModel: UserManagementViewModel
    private lateinit var session: SessionManager
    private lateinit var attentionAdapter: AttentionAdapter
    private lateinit var activityFeedAdapter: DashboardActivityAdapter

    private var signalRClient: com.zynexbd.livetracking.network.SignalRClient? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAdminOverviewDashboardBinding.inflate(layoutInflater)
        setContentView(binding.root)

        session = SessionManager(this)
        viewModel = ViewModelProvider(this)[UserManagementViewModel::class.java]

        setupAdminDrawer(binding.drawerLayout, binding.navigationView, binding.buttonMenu, R.id.nav_overview)

        binding.bottomNavigationView.selectedItemId = R.id.nav_admin_overview
        binding.bottomNavigationView.setOnItemSelectedListener { menuItem ->
            when (menuItem.itemId) {
                R.id.nav_admin_overview -> true
                R.id.nav_admin_map -> {
                    startActivity(Intent(this, AdminDashboardActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    })
                    @Suppress("DEPRECATION")
                    overridePendingTransition(0, 0)
                    true
                }
                R.id.nav_admin_route -> {
                    startActivity(Intent(this, AdminRouteHistoryActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    })
                    @Suppress("DEPRECATION")
                    overridePendingTransition(0, 0)
                    true
                }
                R.id.nav_admin_users -> {
                    startActivity(Intent(this, UserManagementActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    })
                    @Suppress("DEPRECATION")
                    overridePendingTransition(0, 0)
                    true
                }
                R.id.nav_admin_leave -> {
                    startActivity(Intent(this, AdminLeaveActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    })
                    @Suppress("DEPRECATION")
                    overridePendingTransition(0, 0)
                    true
                }
                else -> false
            }
        }

        binding.buttonNavCenterHome.setOnClickListener {
            binding.bottomNavigationView.selectedItemId = R.id.nav_admin_overview
        }

        // Quick Executive Action Hub Click Listeners
        binding.cardActionLiveMap.setOnClickListener {
            startActivity(Intent(this, AdminDashboardActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
        binding.cardActionReports.setOnClickListener {
            startActivity(Intent(this, AdminPerformanceActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
        binding.cardActionLeaves.setOnClickListener {
            startActivity(Intent(this, AdminLeaveActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
        binding.cardActionAttendance.setOnClickListener {
            startActivity(Intent(this, AdminAttendanceActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            })
            @Suppress("DEPRECATION")
            overridePendingTransition(0, 0)
        }
        val isEn = com.zynexbd.livetracking.utils.LanguageManager.getLanguage(this) == com.zynexbd.livetracking.utils.LanguageManager.LANG_EN
        binding.buttonAdminLanguage.text = if (isEn) "🌐 English" else "🌐 বাংলা"
        binding.buttonAdminLanguage.setOnClickListener {
            showLanguageSelectionDialog()
        }

        binding.buttonAddUser.setOnClickListener {
            startActivity(Intent(this, CreateUserActivity::class.java))
        }

        // Setup Attention RecyclerView
        attentionAdapter = AttentionAdapter { item -> handleAttentionAction(item) }
        binding.recyclerAttention.layoutManager = LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)
        binding.recyclerAttention.adapter = attentionAdapter

        // Setup Activity Feed RecyclerView
        activityFeedAdapter = DashboardActivityAdapter(emptyList())
        binding.recyclerActivityFeed.layoutManager = LinearLayoutManager(this)
        binding.recyclerActivityFeed.adapter = activityFeedAdapter

        binding.swipeRefreshLayout.setOnRefreshListener {
            loadDashboardData()
        }

        viewModel.error.observe(this) { message ->
            if (!message.isNullOrBlank()) {
                Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
            }
        }

        com.zynexbd.livetracking.utils.AppUpdateHelper.checkForUpdate(this, lifecycleScope)
    }

    override fun onBackPressed() {
        if (binding.drawerLayout.isDrawerOpen(GravityCompat.START)) {
            binding.drawerLayout.closeDrawer(GravityCompat.START)
        } else {
            super.onBackPressed()
        }
    }

    override fun onResume() {
        super.onResume()
        binding.navigationView.setCheckedItem(R.id.nav_overview)
        binding.bottomNavigationView.selectedItemId = R.id.nav_admin_overview
        loadDashboardData()
        if (signalRClient == null) {
            signalRClient = com.zynexbd.livetracking.network.SignalRClient(this).apply {
                connect(onNotificationReceived = {
                    runOnUiThread { loadDashboardData() }
                })
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        signalRClient?.disconnect()
        signalRClient = null
    }

    private fun loadDashboardData() {
        binding.swipeRefreshLayout.isRefreshing = true
        lifecycleScope.launch {
            try {
                val api = RetrofitClient.getApiService(this@AdminOverviewDashboardActivity)

                val summaryDeferred = async { api.getExecutiveSummary() }
                val currentMonth = Calendar.getInstance().get(Calendar.MONTH) + 1
                val currentYear = Calendar.getInstance().get(Calendar.YEAR)
                val reportDeferred = async { api.getEmployeePerformanceReport(year = currentYear, month = currentMonth) }
                val subDeferred = async { api.getSubscriptionStatus() }

                val summaryRes = summaryDeferred.await()
                val reportRes = reportDeferred.await()
                val subRes = subDeferred.await()

                // Subscription Warning Banner / Modal Check
                if (subRes.isSuccessful && subRes.body() != null) {
                    val sub = subRes.body()!!
                    if (sub.isExpired) {
                        PaymentExpiredDialog.show(this@AdminOverviewDashboardActivity, sub)
                    } else if (sub.isWarningPeriod) {
                        binding.cardSubscriptionWarningBanner.visibility = View.VISIBLE
                        val formattedDate = formatUtcDate(sub.paymentDueDate)
                        val isEn = LanguageManager.isEnglish(this@AdminOverviewDashboardActivity)
                        if (isEn) {
                            binding.textSubscriptionWarningTitle.text = "⚠️ Subscription Payment Warning"
                            binding.textSubscriptionWarningMessage.text = "${sub.daysRemaining} days remaining (Due: $formattedDate)"
                        } else {
                            binding.textSubscriptionWarningTitle.text = "⚠️ বিল পরিশোধের সতর্কতা"
                            binding.textSubscriptionWarningMessage.text = "মেয়াদ শেষ হতে আর ${sub.daysRemaining} দিন বাকি আছে (মেয়াদ: $formattedDate)"
                        }
                        binding.buttonPayNow.setOnClickListener {
                            PaymentExpiredDialog.show(this@AdminOverviewDashboardActivity, sub)
                        }
                    } else {
                        binding.cardSubscriptionWarningBanner.visibility = View.GONE
                    }
                }

                // 1. Process KPI Summary, Attendance Donut, Weekly Velocity & Daily Activities
                if (summaryRes.isSuccessful && summaryRes.body() != null) {
                    val summary = summaryRes.body()!!
                    binding.textMetricTotalUsers.text = summary.totalUsers.toString()
                    binding.textMetricActiveDrivers.text = "${summary.activeUsers} Active Officers"
                    binding.textMetricOnlineTracking.text = summary.onlineTrackingUsers.toString()
                    binding.textMetricPunchedIn.text = "${summary.todayPunchInCount} Duty In Today"
                    binding.textMetricAbsent.text = summary.todayAbsentCount.toString()
                    binding.textMetricPendingLeaves.text = summary.pendingLeaveRequestsCount.toString()
                    binding.textMetricPendingFollowups.text = "${summary.pendingCustomerFollowUpsCount} Follow-Ups"
                    binding.textMetricGpsDisabled.text = "${summary.gpsDisabledUsersCount} GPS Off / Late"

                    if (summary.attentionItems.isNotEmpty()) {
                        binding.containerAttentionSection.visibility = View.VISIBLE
                        attentionAdapter.setItems(summary.attentionItems)
                    } else {
                        binding.containerAttentionSection.visibility = View.GONE
                    }

                    // 2. Process Attendance Donut / Pie Chart (Directly from accurate daily summary)
                    val onTimeCount = summary.todayOnTimeCount
                    val lateCount = summary.todayLateCount
                    val approvedLeavesToday = summary.todayOnLeaveCount
                    val absentCount = summary.todayAbsentCount
                    val attendanceRate = summary.todayAttendanceRate

                    val donutSlices = listOf(
                        DonutChartView.Slice("On Time", onTimeCount.toFloat(), Color.parseColor("#10B981")),
                        DonutChartView.Slice("Late", lateCount.toFloat(), Color.parseColor("#F59E0B")),
                        DonutChartView.Slice("Leave", approvedLeavesToday.toFloat(), Color.parseColor("#8B5CF6")),
                        DonutChartView.Slice("Absent", absentCount.toFloat(), Color.parseColor("#EF4444"))
                    )
                    binding.donutChartAttendance.setData(donutSlices, "$attendanceRate%", "Present Today")
                    binding.textChartOnTime.text = "🟢 $onTimeCount On Time"
                    binding.textChartLate.text = "🟡 $lateCount Late Entry"
                    binding.textChartLeave.text = "🏖️ $approvedLeavesToday On Leave"
                    binding.textChartAbsent.text = "🔴 $absentCount Absent"

                    // 3. Process Weekly Field Activity Bar Chart (from API aggregated 7-day data)
                    if (summary.weeklyFieldVelocity.isNotEmpty()) {
                        val barEntries = summary.weeklyFieldVelocity.map { day ->
                            BarChartView.BarEntry(day.dayLabel, day.visitCount.toFloat(), day.followUpCount.toFloat())
                        }
                        binding.barChartWeeklyActivity.setData(barEntries)
                    }

                    // 4. Process Live Daily Activity Feed (TODAY'S ACTIVITIES ONLY)
                    val activities = mutableListOf<DashboardActivityItem>()
                    for (item in summary.dailyActivities) {
                        val iconRes = when (item.activityType) {
                            "LEAVE" -> R.drawable.ic_leave_custom
                            "VISIT" -> R.drawable.ic_pulse
                            else -> R.drawable.ic_attendance_custom
                        }
                        activities.add(
                            DashboardActivityItem(
                                title = item.title,
                                subtitle = item.subtitle,
                                time = item.time,
                                tag = item.tag,
                                tagColor = item.tagColor,
                                iconRes = iconRes
                            )
                        )
                    }

                    if (activities.isNotEmpty()) {
                        binding.textNoRecentActivity.visibility = View.GONE
                        binding.recyclerActivityFeed.visibility = View.VISIBLE
                        activityFeedAdapter.setItems(activities)
                    } else {
                        binding.textNoRecentActivity.visibility = View.VISIBLE
                        binding.recyclerActivityFeed.visibility = View.GONE
                    }
                }

                // 5. Process Top Performers / Leaderboard
                if (reportRes.isSuccessful && reportRes.body() != null) {
                    val employees = reportRes.body()?.employees.orEmpty().sortedByDescending { it.totalVisits + it.completedFollowUps }
                    if (employees.isNotEmpty()) {
                        val p1 = employees[0]
                        val name1 = (p1.fullName ?: "").ifBlank { p1.username ?: "Officer" }
                        binding.textTopPerformer1Name.text = name1
                        binding.textTopPerformer1Stats.text = "📍 ${p1.totalVisits} Visits • ${p1.completedFollowUps} F-Up"
                    }
                    if (employees.size > 1) {
                        val p2 = employees[1]
                        val name2 = (p2.fullName ?: "").ifBlank { p2.username ?: "Officer" }
                        binding.textTopPerformer2Name.text = name2
                        binding.textTopPerformer2Stats.text = "📍 ${p2.totalVisits} Visits • ${p2.completedFollowUps} F-Up"
                    }
                    if (employees.size > 2) {
                        val p3 = employees[2]
                        val name3 = (p3.fullName ?: "").ifBlank { p3.username ?: "Officer" }
                        binding.textTopPerformer3Name.text = name3
                        binding.textTopPerformer3Stats.text = "📍 ${p3.totalVisits} Visits • ${p3.completedFollowUps} F-Up"
                    }
                }

            } catch (e: Exception) {
                // Fallback
            } finally {
                binding.swipeRefreshLayout.isRefreshing = false
            }
        }
    }

    private fun handleAttentionAction(item: AttentionItem) {
        when (item.type) {
            "PendingLeave" -> startActivity(Intent(this, AdminLeaveActivity::class.java))
            "MissedFollowUp" -> startActivity(Intent(this, AdminPerformanceActivity::class.java))
            else -> {
                if (item.userId != null) {
                    startActivity(Intent(this, AdminDashboardActivity::class.java))
                } else {
                    Toast.makeText(this, item.title, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun formatUtcDate(dateStr: String?): String {
        if (dateStr.isNullOrBlank()) return "N/A"
        return try {
            val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val date = parser.parse(dateStr)
            val formatter = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).apply {
                timeZone = TimeZone.getDefault()
            }
            formatter.format(date ?: return dateStr)
        } catch (e: Exception) {
            dateStr
        }
    }
}
