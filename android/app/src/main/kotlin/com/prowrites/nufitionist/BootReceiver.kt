// android/app/src/main/kotlin/com/example/user_onboarding/BootReceiver.kt
package com.example.user_onboarding

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted - notifications need to be rescheduled")
            
            // Set a flag that the app should reschedule notifications on next launch
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("flutter.needs_notification_reschedule", true).apply()
            
            Log.d("BootReceiver", "Set reschedule flag - notifications will be rescheduled on app launch")
        }
    }
}