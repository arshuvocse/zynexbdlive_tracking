package com.zynexbd.livetracking.data

import android.util.Log
import com.google.gson.Gson
import com.microsoft.signalr.HubConnection
import com.microsoft.signalr.HubConnectionBuilder
import com.microsoft.signalr.HubConnectionState
import com.zynexbd.livetracking.BuildConfig

/**
 * Wraps the SignalR connection used by the Admin app to receive live
 * location broadcasts from LocationHub. The JWT is passed as an
 * access_token query param since the WebSocket handshake can't carry
 * a custom Authorization header on all transports (see Program.cs
 * OnMessageReceived handling on the API side).
 */
class SignalRClient(private val token: String) {

    private var hubConnection: HubConnection? = null
    private val gson = Gson()

    fun connect(onLocationUpdate: (UserLocationResponse) -> Unit, onStateChanged: ((HubConnectionState) -> Unit)? = null) {
        val connection = HubConnectionBuilder.create(BuildConfig.SIGNALR_HUB_URL)
            .withAccessTokenProvider(io.reactivex.rxjava3.core.Single.just(token))
            .build()

        connection.on("ReceiveLocationUpdate", { payload ->
            onLocationUpdate(payload)
        }, UserLocationResponse::class.java)

        connection.onClosed { error ->
            Log.w(TAG, "SignalR connection closed", error)
            onStateChanged?.invoke(HubConnectionState.DISCONNECTED)
        }

        connection.start().subscribe(
            { Log.i(TAG, "SignalR connected") },
            { error -> Log.e(TAG, "SignalR connection failed", error) }
        )

        hubConnection = connection
    }

    fun disconnect() {
        hubConnection?.stop()
        hubConnection = null
    }

    companion object {
        private const val TAG = "SignalRClient"
    }
}
