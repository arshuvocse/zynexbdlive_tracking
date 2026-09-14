package com.zynexbd.livetracking.utils

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.zynexbd.livetracking.R

enum class ToastType {
    SUCCESS,
    ERROR,
    WARNING,
    INFO
}

/**
 * Modern floating pill / card toast notification with custom background,
 * circular status badge, crisp typography, and smooth enter/exit animations.
 */
object CustomToast {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeToastView: View? = null
    private var activeDismissRunnable: Runnable? = null

    fun showSuccess(context: Context, message: String, title: String? = null) {
        show(context, message, ToastType.SUCCESS, title)
    }

    fun showError(context: Context, message: String, title: String? = null) {
        show(context, message, ToastType.ERROR, title)
    }

    fun showWarning(context: Context, message: String, title: String? = null) {
        show(context, message, ToastType.WARNING, title)
    }

    fun showInfo(context: Context, message: String, title: String? = null) {
        show(context, message, ToastType.INFO, title)
    }

    private fun sanitizeMessage(message: String): String {
        val trimmed = message.trim()
        if (NetworkErrorHandler.isHtml(trimmed)) {
            return "সার্ভারে সমস্যা হয়েছে। অনুগ্রহ করে কিছুক্ষণ পর চেষ্টা করুন।"
        }
        return trimmed
    }

    fun show(
        context: Context,
        message: String,
        type: ToastType = ToastType.INFO,
        title: String? = null,
        durationMs: Long = 3200L
    ) {
        val cleanMsg: CharSequence = sanitizeMessage(message)
        if (cleanMsg.isBlank()) return

        mainHandler.post {
            val activity = findActivity(context)
            if (activity == null || activity.isFinishing || activity.isDestroyed) {
                // Fallback to standard Toast if no foreground activity is attached
                Toast.makeText(context.applicationContext, cleanMsg, Toast.LENGTH_SHORT).show()
                return@post
            }

            try {
                displayFloatingToast(activity, cleanMsg.toString(), type, title, durationMs)
            } catch (e: Exception) {
                // Safety net fallback
                Toast.makeText(activity, cleanMsg, Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun displayFloatingToast(
        activity: Activity,
        message: String,
        type: ToastType,
        title: String?,
        durationMs: Long
    ) {
        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return

        // Remove any currently active toast view
        activeDismissRunnable?.let { mainHandler.removeCallbacks(it) }
        activeToastView?.let {
            (it.parent as? ViewGroup)?.removeView(it)
            activeToastView = null
        }

        val ctx = activity
        val density = ctx.resources.displayMetrics.density
        fun dp(v: Float): Int = (v * density + 0.5f).toInt()

        // Configuration based on ToastType
        val (badgeBgColor, strokeColor, iconRes, defaultTitle) = when (type) {
            ToastType.SUCCESS -> Quad(
                Color.parseColor("#10B981"), // Emerald 500
                Color.parseColor("#059669"), // Emerald 600
                R.drawable.ic_check_circle,
                "সফল"
            )
            ToastType.ERROR -> Quad(
                Color.parseColor("#EF4444"), // Red 500
                Color.parseColor("#DC2626"), // Red 600
                R.drawable.ic_cancel,
                "ত্রুটি"
            )
            ToastType.WARNING -> Quad(
                Color.parseColor("#F59E0B"), // Amber 500
                Color.parseColor("#D97706"), // Amber 600
                R.drawable.ic_bell_notification,
                "সতর্কতা"
            )
            ToastType.INFO -> Quad(
                Color.parseColor("#3B82F6"), // Blue 500
                Color.parseColor("#2563EB"), // Blue 600
                R.drawable.ic_pulse,
                "তথ্য"
            )
        }

        // Top-level Toast Container (Pill Card)
        val toastContainer = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(14f), dp(11f), dp(14f), dp(11f))
            elevation = dp(10f).toFloat()

            // Dark sleek modern slate pill background with subtle colored border
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(24f).toFloat()
                setColor(Color.parseColor("#1E293B")) // Slate 800
                setStroke(dp(1.5f), strokeColor)
            }
            background = bg
        }

        // 1. Icon Badge (Circular)
        val badgeFrame = FrameLayout(ctx).apply {
            val size = dp(34f)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                marginEnd = dp(12f)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(badgeBgColor)
            }
        }

        val iconView = ImageView(ctx).apply {
            val iconSize = dp(20f)
            layoutParams = FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
            setImageResource(iconRes)
            imageTintList = ColorStateList.valueOf(Color.WHITE)
        }
        badgeFrame.addView(iconView)
        toastContainer.addView(badgeFrame)

        // 2. Text Container
        val textContainer = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }

        val displayTitle = title ?: if (type == ToastType.ERROR) defaultTitle else null
        if (!displayTitle.isNullOrBlank()) {
            val titleView = TextView(ctx).apply {
                text = displayTitle
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
                setLineSpacing(dp(1f).toFloat(), 1f)
            }
            textContainer.addView(titleView)
        }

        val msgView = TextView(ctx).apply {
            text = message
            setTextColor(Color.parseColor("#F8FAFC")) // Crisp Slate 50
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            maxLines = 4
            ellipsize = android.text.TextUtils.TruncateAt.END
            setLineSpacing(dp(2f).toFloat(), 1f)
        }
        textContainer.addView(msgView)
        toastContainer.addView(textContainer)

        // 3. Subtle close / dismiss button
        val closeBtn = ImageView(ctx).apply {
            val btnSize = dp(20f)
            layoutParams = LinearLayout.LayoutParams(btnSize, btnSize).apply {
                marginStart = dp(10f)
            }
            setImageResource(R.drawable.ic_cancel)
            imageTintList = ColorStateList.valueOf(Color.parseColor("#94A3B8"))
            alpha = 0.65f
        }
        toastContainer.addView(closeBtn)

        // Position: Top floating pill with safe status bar margin
        val statusBarHeight = getStatusBarHeight(activity)
        val topMargin = statusBarHeight + dp(12f)

        val params = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            setMargins(dp(16f), topMargin, dp(16f), 0)
        }

        // Slide down animation
        toastContainer.translationY = -dp(100f).toFloat()
        toastContainer.alpha = 0f

        root.addView(toastContainer, params)
        activeToastView = toastContainer

        toastContainer.animate()
            .translationY(0f)
            .alpha(1f)
            .setDuration(280)
            .setInterpolator(android.view.animation.DecelerateInterpolator())
            .start()

        // Auto dismiss
        val dismissAction = Runnable {
            dismissToast(toastContainer)
        }
        activeDismissRunnable = dismissAction
        mainHandler.postDelayed(dismissAction, durationMs)

        // Tap to dismiss
        toastContainer.setOnClickListener {
            mainHandler.removeCallbacks(dismissAction)
            dismissToast(toastContainer)
        }
    }

    private fun dismissToast(view: View) {
        if (view.parent == null) return
        val density = view.resources.displayMetrics.density
        val dismissOffset = -(100f * density)

        view.animate()
            .translationY(dismissOffset)
            .alpha(0f)
            .setDuration(220)
            .setInterpolator(android.view.animation.AccelerateInterpolator())
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    (view.parent as? ViewGroup)?.removeView(view)
                    if (activeToastView == view) {
                        activeToastView = null
                        activeDismissRunnable = null
                    }
                }
            })
            .start()
    }

    private fun getStatusBarHeight(activity: Activity): Int {
        var result = 0
        val resourceId = activity.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            result = activity.resources.getDimensionPixelSize(resourceId)
        }
        if (result <= 0) {
            val density = activity.resources.displayMetrics.density
            result = (24 * density).toInt()
        }
        return result
    }

    private fun findActivity(context: Context): Activity? {
        var ctx: Context? = context
        while (ctx is ContextWrapper) {
            if (ctx is Activity) return ctx
            ctx = ctx.baseContext
        }
        return null
    }

    private data class Quad<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
}

// Global Extension Functions
fun Activity.showSuccessToast(message: String, title: String? = null) =
    CustomToast.showSuccess(this, message, title)

fun Activity.showErrorToast(message: String, title: String? = null) =
    CustomToast.showError(this, message, title)

fun Activity.showWarningToast(message: String, title: String? = null) =
    CustomToast.showWarning(this, message, title)

fun Activity.showInfoToast(message: String, title: String? = null) =
    CustomToast.showInfo(this, message, title)

fun Context.showCustomToast(message: String, type: ToastType = ToastType.INFO, title: String? = null) =
    CustomToast.show(this, message, type, title)
