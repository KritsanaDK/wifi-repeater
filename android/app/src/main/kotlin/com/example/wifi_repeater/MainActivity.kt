package com.example.wifi_repeater

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.SupplicantState
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.example.wifi_repeater/wifi"
        private const val WIFI_PERMISSION_REQUEST_CODE = 7001

        private val WIFI_SETTINGS_ACTIONS = listOf(
            Settings.ACTION_WIFI_SETTINGS,
            Settings.ACTION_WIRELESS_SETTINGS,
            Settings.ACTION_SETTINGS,
        )

        // A normal third-party app cannot toggle Internet tethering through a public API,
        // and Android has no public, guaranteed deep link directly to its tethering page.
        // The public wireless settings screen is therefore the closest safe entry point.
        private val HOTSPOT_SETTINGS_ACTIONS = listOf(
            Settings.ACTION_WIRELESS_SETTINGS,
            Settings.ACTION_SETTINGS,
        )
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getStatus" -> result.success(getWifiStatus())
                        "requestWifiPermission" -> requestWifiPermission(result)
                        "openWifiSettings" -> openSettings(
                            actions = WIFI_SETTINGS_ACTIONS,
                            unavailableMessage = "No system Wi-Fi settings screen is available.",
                            result = result,
                        )
                        "openHotspotSettings" -> openSettings(
                            actions = HOTSPOT_SETTINGS_ACTIONS,
                            unavailableMessage = "No system wireless settings screen is available.",
                            result = result,
                        )
                        else -> result.notImplemented()
                    }
                } catch (exception: SecurityException) {
                    result.error(
                        "permission_denied",
                        exception.message ?: "Android denied access to Wi-Fi information.",
                        null,
                    )
                } catch (exception: Exception) {
                    result.error(
                        "android_error",
                        exception.message ?: "The Android Wi-Fi operation failed.",
                        exception.javaClass.simpleName,
                    )
                }
            }
    }

    private fun getWifiStatus(): Map<String, Any?> {
        val wifiManager = applicationContext.getSystemService(WifiManager::class.java)
            ?: throw IllegalStateException("The Wi-Fi service is unavailable on this device.")
        val connectivityManager = getSystemService(ConnectivityManager::class.java)
            ?: throw IllegalStateException("The connectivity service is unavailable on this device.")
        val requiredPermission = requiredRuntimePermission()
        val permissionGranted = requiredPermission == null ||
            checkSelfPermission(requiredPermission) == PackageManager.PERMISSION_GRANTED
        val connection = readWifiConnection(
            wifiManager = wifiManager,
            connectivityManager = connectivityManager,
            mayReadSsid = permissionGranted,
        )

        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "wifiEnabled" to wifiManager.isWifiEnabled,
            "wifiConnected" to connection.connected,
            "wifiHasInternet" to connection.hasInternet,
            "wifiName" to connection.ssid,
            "requiredPermission" to requiredPermission,
            "permissionNeeded" to !permissionGranted,
            "permissionGranted" to permissionGranted,
            "canOpenHotspotSettings" to canResolveAny(HOTSPOT_SETTINGS_ACTIONS),
            "concurrentModeSupported" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                wifiManager.isStaApConcurrencySupported
            } else {
                null
            },
        )
    }

    @Suppress("DEPRECATION")
    private fun readWifiConnection(
        wifiManager: WifiManager,
        connectivityManager: ConnectivityManager,
        mayReadSsid: Boolean,
    ): WifiConnection {
        val activeNetwork = connectivityManager.activeNetwork
        val activeCapabilities = activeNetwork?.let(connectivityManager::getNetworkCapabilities)
        val wifiCapabilities = if (
            activeCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        ) {
            activeCapabilities
        } else {
            connectivityManager.allNetworks.firstNotNullOfOrNull { network ->
                connectivityManager.getNetworkCapabilities(network)?.takeIf {
                    it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                }
            }
        }

        val capabilitiesWifiInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            wifiCapabilities?.transportInfo as? WifiInfo
        } else {
            null
        }
        val legacyWifiInfo = runCatching { wifiManager.connectionInfo }.getOrNull()
        val legacyConnected = legacyWifiInfo?.let {
            it.networkId != -1 && it.supplicantState == SupplicantState.COMPLETED
        } == true
        val connected = wifiCapabilities != null || legacyConnected
        val hasInternet = wifiCapabilities?.let {
            it.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                it.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        }

        val ssid = if (connected && mayReadSsid) {
            sanitizeSsid(capabilitiesWifiInfo?.ssid)
                ?: sanitizeSsid(legacyWifiInfo?.ssid)
        } else {
            null
        }
        return WifiConnection(
            connected = connected,
            hasInternet = hasInternet,
            ssid = ssid,
        )
    }

    private fun sanitizeSsid(rawSsid: String?): String? {
        val trimmed = rawSsid?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        if (trimmed.equals(WifiManager.UNKNOWN_SSID, ignoreCase = true)) return null

        val unquoted = if (
            trimmed.length >= 2 && trimmed.first() == '"' && trimmed.last() == '"'
        ) {
            trimmed.substring(1, trimmed.length - 1)
        } else {
            trimmed
        }
        return unquoted.trim().takeIf { it.isNotEmpty() }
    }

    // SSID is location-sensitive connection information, including on Android 13+.
    // NEARBY_WIFI_DEVICES is not needed because this bridge does not scan, connect,
    // or start a local-only hotspot itself.
    private fun requiredRuntimePermission(): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Manifest.permission.ACCESS_FINE_LOCATION
        } else {
            null
        }

    private fun requestWifiPermission(result: MethodChannel.Result) {
        val permission = requiredRuntimePermission()
        if (permission == null || checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A Wi-Fi permission request is already in progress.",
                null,
            )
            return
        }

        pendingPermissionResult = result
        try {
            requestPermissions(arrayOf(permission), WIFI_PERMISSION_REQUEST_CODE)
        } catch (exception: Exception) {
            pendingPermissionResult = null
            throw exception
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != WIFI_PERMISSION_REQUEST_CODE) return

        val callback = pendingPermissionResult
        pendingPermissionResult = null
        val permission = requiredRuntimePermission()
        val granted = permission == null ||
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        callback?.success(granted)
    }

    private fun canResolveAny(actions: List<String>): Boolean = actions.any { action ->
        Intent(action).resolveActivity(packageManager) != null
    }

    private fun openSettings(
        actions: List<String>,
        unavailableMessage: String,
        result: MethodChannel.Result,
    ) {
        var lastFailure: Exception? = null
        for (action in actions) {
            val intent = Intent(action)
            if (intent.resolveActivity(packageManager) == null) continue
            try {
                startActivity(intent)
                result.success(true)
                return
            } catch (exception: ActivityNotFoundException) {
                lastFailure = exception
            } catch (exception: SecurityException) {
                lastFailure = exception
            }
        }

        result.error(
            "settings_unavailable",
            unavailableMessage,
            lastFailure?.message,
        )
    }

    override fun onDestroy() {
        pendingPermissionResult?.error(
            "activity_destroyed",
            "The activity closed before the permission request completed.",
            null,
        )
        pendingPermissionResult = null
        super.onDestroy()
    }

    private data class WifiConnection(
        val connected: Boolean,
        val hasInternet: Boolean?,
        val ssid: String?,
    )
}
