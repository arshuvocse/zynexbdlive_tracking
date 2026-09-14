package com.zynexbd.livetracking.utils

import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import javax.net.ssl.SSLException
import org.json.JSONObject

/**
 * Central utility to convert network/IO exceptions and HTTP error responses into user-friendly Bangla messages.
 *
 * Use [friendlyMessage] when catching exceptions from Retrofit/OkHttp calls,
 * and [parseHttpError] when handling non-successful HTTP responses.
 */
object NetworkErrorHandler {

    /**
     * Checks if a string looks like an HTML document or snippet (e.g. IIS error pages, DOCTYPE, <html> tags).
     */
    fun isHtml(text: String): Boolean {
        val trimmed = text.trim()
        return trimmed.startsWith("<", ignoreCase = true) ||
            trimmed.contains("<!DOCTYPE", ignoreCase = true) ||
            trimmed.contains("<html", ignoreCase = true) ||
            trimmed.contains("</html>", ignoreCase = true) ||
            trimmed.contains("<head", ignoreCase = true) ||
            trimmed.contains("<body", ignoreCase = true)
    }

    /**
     * Parses an HTTP error response (status code and optional error body) into a user-friendly message.
     * Prevents raw HTML, XML, or exception stacktraces from being shown in UI/Toasts.
     */
    fun parseHttpError(code: Int, errorBody: String?, fallbackMessage: String? = null): String {
        if (errorBody.isNullOrBlank()) {
            return fallbackMessage ?: httpStatusToFriendlyMessage(code)
        }

        val trimmed = errorBody.trim()

        // 1. If HTML (e.g. IIS 404/500/502 error page), never show raw HTML
        if (isHtml(trimmed)) {
            return fallbackMessage ?: httpStatusToFriendlyMessage(code)
        }

        // 2. If JSON, extract friendly error/message
        if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
            try {
                val json = JSONObject(trimmed)
                val msg = when {
                    json.has("message") -> json.optString("message")
                    json.has("error") -> json.optString("error")
                    json.has("detail") -> json.optString("detail")
                    json.has("title") -> json.optString("title")
                    else -> null
                }?.trim()

                if (!msg.isNullOrBlank() && !isHtml(msg)) {
                    return msg
                }

                // Handle ASP.NET ModelState validation errors: {"errors":{"Username":["..."]}}
                if (json.has("errors")) {
                    val errorsObj = json.optJSONObject("errors")
                    if (errorsObj != null) {
                        val firstKey = errorsObj.keys().asSequence().firstOrNull()
                        if (firstKey != null) {
                            val arr = errorsObj.optJSONArray(firstKey)
                            if (arr != null && arr.length() > 0) {
                                val validationErr = arr.optString(0).trim()
                                if (validationErr.isNotBlank() && !isHtml(validationErr)) {
                                    return validationErr
                                }
                            }
                        }
                    }
                }
            } catch (ignored: Exception) {
            }
        }

        // 3. Plain text error (e.g. short string from server), but not HTML or long exception dump
        if (!isHtml(trimmed) && trimmed.length <= 150) {
            return trimmed
        }

        return fallbackMessage ?: httpStatusToFriendlyMessage(code)
    }

    /**
     * Translates standard HTTP status codes into clear, user-friendly Bangla messages.
     */
    fun httpStatusToFriendlyMessage(code: Int): String {
        return when (code) {
            400 -> "অনুরোধটি সঠিক নয় (Bad Request 400)।"
            401 -> "ইউজারনেম বা পাসওয়ার্ড সঠিক নয়।"
            403 -> "আপনার এই কাজটি করার অনুমতি নেই (Access Denied)।"
            404 -> "সার্ভারে রিকোয়েস্ট পাওয়া যায়নি (HTTP 404)। দয়া করে অ্যাপটি আপডেট করুন অথবা সার্ভার লিংক চেক করুন।"
            500 -> "সার্ভারে অভ্যন্তরীণ সমস্যা হয়েছে (Server Error 500)। কিছুক্ষণ পর আবার চেষ্টা করুন।"
            502, 503, 504 -> "সার্ভার এই মুহূর্তে বন্ধ বা রক্ষণাবেক্ষণে রয়েছে (HTTP $code)। কিছুক্ষণ পর চেষ্টা করুন।"
            else -> "সার্ভার ত্রুটি হয়েছে (HTTP $code)। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।"
        }
    }

    /**
     * Returns a user-friendly Bangla error message for the given [throwable].
     *
     * Priority order:
     * 1. [UnknownHostException]  – DNS failure / no internet / wrong base URL
     * 2. [ConnectException]      – server not reachable (port closed, firewall, wrong URL)
     * 3. [SocketTimeoutException] – server is too slow or unreachable (timeout)
     * 4. [SSLException]          – TLS/certificate problem
     * 5. Generic fallback        – any other exception
     */
    fun friendlyMessage(throwable: Throwable): String {
        return when (throwable) {
            is UnknownHostException ->
                "সার্ভারের সাথে সংযোগ করা সম্ভব হয়নি।\nইন্টারনেট সংযোগ চেক করুন অথবা পরে আবার চেষ্টা করুন।"

            is ConnectException ->
                "সার্ভার এই মুহূর্তে পাওয়া যাচ্ছে না।\nকিছুক্ষণ পর আবার চেষ্টা করুন।"

            is SocketTimeoutException ->
                "সার্ভার সাড়া দিতে অনেক সময় নিচ্ছে (Timeout)।\nইন্টারনেট স্পিড চেক করুন অথবা পরে আবার চেষ্টা করুন।"

            is SSLException ->
                "সিকিউর সংযোগ স্থাপন করা যায়নি (SSL Error)।\nঅ্যাডমিনকে জানান।"

            else -> {
                val raw = throwable.message ?: ""
                when {
                    isHtml(raw) -> "সার্ভারে ত্রুটি হয়েছে। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।"
                    isNetworkRelated(raw) -> "নেটওয়ার্ক সমস্যা হয়েছে।\nইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।"
                    raw.length > 200 -> "অপ্রত্যাশিত ত্রুটি হয়েছে। আবার চেষ্টা করুন।"
                    else -> raw.ifBlank { "অপ্রত্যাশিত ত্রুটি হয়েছে। আবার চেষ্টা করুন।" }
                }
            }
        }
    }

    /**
     * Heuristic to detect whether a raw exception message is network/IO related
     * (so we don't expose raw Java class names to the user).
     */
    private fun isNetworkRelated(message: String): Boolean {
        val lower = message.lowercase()
        return lower.contains("failed to connect") ||
            lower.contains("unable to resolve") ||
            lower.contains("network") ||
            lower.contains("timeout") ||
            lower.contains("connection") ||
            lower.contains("socket") ||
            lower.contains("econnrefused") ||
            lower.contains("unreachable") ||
            lower.contains("no route to host") ||
            lower.contains("ssl") ||
            lower.contains("hostname") ||
            lower.contains("eof") ||
            lower.contains("broken pipe")
    }
}

/**
 * Extension on [Result] that remaps any [Throwable] in a failure to a
 * user-friendly message via [NetworkErrorHandler.friendlyMessage].
 */
fun <T> Result<T>.mapNetworkError(): Result<T> =
    exceptionOrNull()?.let { ex ->
        Result.failure(Throwable(NetworkErrorHandler.friendlyMessage(ex)))
    } ?: this

/**
 * Convenience top-level suspend wrapper for repository functions.
 * Equivalent to `runCatching { block() }.mapNetworkError()`.
 */
suspend fun <T> safeApiCall(block: suspend () -> T): Result<T> =
    runCatching { block() }.mapNetworkError()
