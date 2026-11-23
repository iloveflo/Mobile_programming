package com.example.my_first_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var notificationChannel: MethodChannel? = null
    private val notifPermissionRequestCode = 1001
    private val notifChannelId = "fincredit_reminders"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = extractNotificationPayload(intent)
        if (payload != null) {
            notificationChannel?.invokeMethod("onNotificationTap", payload)
        }
    }

    private fun extractNotificationPayload(intent: Intent?): Map<String, Any>? {
        if (intent == null || !intent.getBooleanExtra("fromNotification", false)) {
            return null
        }
        val map = mutableMapOf<String, Any>(
            "tabIndex" to intent.getIntExtra("tabIndex", 2)
        )
        val scheduleId = intent.getIntExtra("scheduleId", -1)
        if (scheduleId > 0) {
            map["scheduleId"] = scheduleId
        }
        intent.removeExtra("fromNotification")
        return map
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notifPermissionRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fincredit/notifications")
        notificationChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialNotificationLaunch" -> {
                        result.success(extractNotificationPayload(intent))
                    }
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val granted = ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) == PackageManager.PERMISSION_GRANTED
                            if (granted) {
                                result.success(true)
                            } else {
                                pendingPermissionResult = result
                                ActivityCompat.requestPermissions(
                                    this,
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    notifPermissionRequestCode
                                )
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "showNotification" -> {
                        val id = call.argument<Int>("id") ?: 1
                        val title = call.argument<String>("title") ?: "FinCredit"
                        val body = call.argument<String>("body") ?: ""
                        val dedupeKey = call.argument<String>("dedupeKey")
                        val scheduleId = call.argument<Int>("scheduleId") ?: -1
                        val tabIndex = call.argument<Int>("tabIndex") ?: 2
                        try {
                            if (!dedupeKey.isNullOrBlank()) {
                                val prefs = getSharedPreferences("fincredit_notifs", Context.MODE_PRIVATE)
                                if (prefs.getBoolean(dedupeKey, false)) {
                                    result.success(false)
                                    return@setMethodCallHandler
                                }
                                prefs.edit().putBoolean(dedupeKey, true).apply()
                            }

                            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val channel = NotificationChannel(
                                    notifChannelId,
                                    "Nhắc nợ & Cảnh báo FinCredit",
                                    NotificationManager.IMPORTANCE_HIGH
                                ).apply {
                                    description = "Thông báo kỳ thanh toán quá hạn, nhắc nợ và biến động tín dụng"
                                }
                                manager.createNotificationChannel(channel)
                            }
                            val launchIntent = Intent(this, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                putExtra("fromNotification", true)
                                putExtra("tabIndex", tabIndex)
                                if (scheduleId > 0) {
                                    putExtra("scheduleId", scheduleId)
                                }
                            }
                            val pendingIntent = PendingIntent.getActivity(
                                this,
                                id,
                                launchIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
                            val notification = NotificationCompat.Builder(this, notifChannelId)
                                .setSmallIcon(R.drawable.ic_notification)
                                .setLargeIcon(largeIcon)
                                .setColor(0xFF0D47A1.toInt())
                                .setSubText("Cảnh báo tín dụng")
                                .setContentTitle(title)
                                .setContentText(body)
                                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                                .setPriority(NotificationCompat.PRIORITY_HIGH)
                                .setOnlyAlertOnce(true)
                                .setAutoCancel(true)
                                .setContentIntent(pendingIntent)
                                .build()
                            manager.notify(id, notification)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NOTIF_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fincredit/launcher")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.error("INVALID_URL", "URL trống", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    "saveAndOpenPdf" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "HoSoNangLuc_FinCredit.pdf"
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID_DATA", "Dữ liệu PDF trống", null)
                            return@setMethodCallHandler
                        }
                        try {
                            var openUri: Uri? = null
                            var savedPath = fileName
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                                    put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                    put(MediaStore.Downloads.IS_PENDING, 1)
                                }
                                val resolver = contentResolver
                                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                                if (uri != null) {
                                    resolver.openOutputStream(uri)?.use { it.write(bytes) }
                                    values.clear()
                                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                                    resolver.update(uri, values, null, null)
                                    openUri = uri
                                    savedPath = "Download/$fileName"
                                }
                            } else {
                                @Suppress("DEPRECATION")
                                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                                if (!dir.exists()) dir.mkdirs()
                                val outFile = File(dir, fileName)
                                FileOutputStream(outFile).use { it.write(bytes) }
                                openUri = Uri.fromFile(outFile)
                                savedPath = outFile.absolutePath
                            }

                            if (openUri != null) {
                                try {
                                    val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(openUri, "application/pdf")
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(viewIntent)
                                } catch (_: Exception) {
                                    // Thiết bị chưa cài app đọc PDF vẫn lưu file vào Download thành công
                                }
                            }
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
