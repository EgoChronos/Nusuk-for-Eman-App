package com.noorforiman.noor_for_iman

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.noorforiman.noor_for_iman/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBackgroundPopups" -> {
                    result.success(checkBackgroundPopups())
                }
                "openOtherPermissions" -> {
                    openOtherPermissions()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkBackgroundPopups(): Boolean {
        // MIUI Specific Ops:
        // 10021: Background Activity Start (Most critical for overlays)
        // 10020: Show when locked (Essential for wake-up overlay)
        // 10034: Custom view notification (Sometimes affects background wake)
        return checkAppOp(10021) && checkAppOp(10020)
    }

    private fun checkAppOp(op: Int): Boolean {
        return try {
            val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val method = appOpsManager.javaClass.getMethod("checkOpNoThrow", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType, String::class.java)
            val result = method.invoke(appOpsManager, op, android.os.Process.myUid(), packageName) as Int
            result == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            true // If it fails, assume allowed (or not on MIUI)
        }
    }

    private fun openOtherPermissions() {
        try {
            val intent = Intent("miui.intent.action.APP_OPS_SETTINGS")
            intent.putExtra("extra_pkgname", packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            val uri = Uri.fromParts("package", packageName, null)
            intent.data = uri
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
}
