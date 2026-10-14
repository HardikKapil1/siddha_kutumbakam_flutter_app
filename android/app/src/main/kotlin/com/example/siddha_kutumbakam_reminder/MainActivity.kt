package com.example.siddha_kutumbakam_reminder

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.siddha_kutumbakam_reminder/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // ── Battery Optimization ───────────────────────────────────────────────
                "requestBatteryOptimizationExemption" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            }
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        try { startActivity(Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)) } catch (_: Exception) {}
                        result.success(null)
                    }
                }

                "isBatteryOptimizationExempt" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }

                // ── Exact Alarm Permission ─────────────────────────────────────────────
                "canScheduleExactAlarms" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val am = getSystemService(AlarmManager::class.java)
                        result.success(am?.canScheduleExactAlarms() ?: false)
                    } else {
                        result.success(true)
                    }
                }

                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }

                // ── Alarm Volume (STREAM_ALARM only) ──────────────────────────────────
                "getAlarmVolume" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    result.success(am.getStreamVolume(AudioManager.STREAM_ALARM))
                }

                "getAlarmMaxVolume" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    result.success(am.getStreamMaxVolume(AudioManager.STREAM_ALARM))
                }

                "setAlarmVolume" -> {
                    val volume = call.argument<Int>("volume")
                        ?: return@setMethodCallHandler result.error("MISSING_ARG", "volume is required", null)
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                    val safeVol = volume.coerceIn(0, maxVol)
                    am.setStreamVolume(AudioManager.STREAM_ALARM, safeVol, AudioManager.FLAG_SHOW_UI)
                    result.success(safeVol)
                }

                "openSoundSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_SOUND_SETTINGS))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }

                // ── Device / OEM Info ─────────────────────────────────────────────────
                // Returns manufacturer + model so Flutter can show OEM-specific autostart
                // instructions. Autostart is a custom OEM permission that cannot be
                // requested programmatically — the user must enable it manually.
                "getDeviceInfo" -> {
                    result.success(mapOf(
                        "brand"        to Build.BRAND.lowercase(),
                        "manufacturer" to Build.MANUFACTURER.lowercase(),
                        "model"        to Build.MODEL,
                        "sdkInt"       to Build.VERSION.SDK_INT,
                    ))
                }

                // Opens the OEM-specific autostart / background app manager screen.
                // Returns false if the intent couldn't be resolved (non-OEM device).
                "openAutostartSettings" -> {
                    val brand = Build.MANUFACTURER.lowercase()
                    val launched = tryLaunchAutostartIntent(brand)
                    result.success(launched)
                }

                // ── Notification Channel Health ────────────────────────────────────────
                // Returns whether the alarm notification channels exist and have sound enabled.
                "getNotificationChannelStatus" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        val channels = nm.notificationChannels
                        val alarmChannels = channels.filter { it.id.startsWith("sk_alarm_") }
                        val hasSound = alarmChannels.any { ch ->
                            ch.importance >= NotificationManager.IMPORTANCE_DEFAULT &&
                            ch.sound != null
                        }
                        result.success(mapOf(
                            "exists"   to alarmChannels.isNotEmpty(),
                            "hasSound" to hasSound,
                            "count"    to alarmChannels.size,
                        ))
                    } else {
                        result.success(mapOf("exists" to true, "hasSound" to true, "count" to 0))
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Tries to launch the OEM-specific autostart / background manager screen.
     * Each OEM uses a different intent — this is not part of AOSP.
     * Returns true if the intent was successfully launched, false otherwise.
     */
    private fun tryLaunchAutostartIntent(brand: String): Boolean {
        val intents = when {
            // Xiaomi MIUI
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> listOf(
                Intent().setClassName("com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"),
                Intent().setClassName("com.miui.securitycenter",
                    "com.miui.securitycenter.MainActivity")
            )
            // Huawei / Honor EMUI
            brand.contains("huawei") || brand.contains("honor") -> listOf(
                Intent().setClassName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
                Intent().setClassName("com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity")
            )
            // OPPO / Realme ColorOS
            brand.contains("oppo") || brand.contains("realme") || brand.contains("oneplus") -> listOf(
                Intent().setClassName("com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.FakeActivity"),
                Intent().setClassName("com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity"),
                Intent().setClassName("com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity")
            )
            // Vivo FuntouchOS / OriginOS
            brand.contains("vivo") -> listOf(
                Intent().setClassName("com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                Intent().setClassName("com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
            )
            // Samsung One UI / TouchWiz
            brand.contains("samsung") -> listOf(
                Intent().setClassName("com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"),
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            )
            // Meizu Flyme
            brand.contains("meizu") -> listOf(
                Intent().setClassName("com.meizu.safe",
                    "com.meizu.safe.permission.SmartPermissionActivity")
            )
            // Asus ZenUI
            brand.contains("asus") -> listOf(
                Intent().setClassName("com.asus.mobilemanager",
                    "com.asus.mobilemanager.MainActivity")
            )
            else -> emptyList()
        }

        for (intent in intents) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
                continue
            }
        }

        // Fallback: open standard app info page
        return try {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            })
            true
        } catch (_: Exception) {
            false
        }
    }
}
