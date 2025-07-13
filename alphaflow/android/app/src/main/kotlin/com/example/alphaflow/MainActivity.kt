package com.blackmere.alphaflow

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.blackmere.alphaflow.widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    updateWidget()
                    result.success(null)
                }
                "sendDataToWidget" -> {
                    val data = call.arguments as? Map<String, Any>
                    sendDataToWidget(data)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun updateWidget() {
        Log.d("MainActivity", "updateWidget called from Flutter")
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(this, AlphaflowWidgetProvider::class.java)
        )
        
        Log.d("MainActivity", "Found ${appWidgetIds.size} widget instances")
        
        if (appWidgetIds.isNotEmpty()) {
            val intent = Intent(this, AlphaflowWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            sendBroadcast(intent)
            Log.d("MainActivity", "Sent widget update broadcast")
        } else {
            Log.d("MainActivity", "No widget instances found")
        }
    }
    
    private fun sendDataToWidget(data: Map<String, Any>?) {
        // For future use - can send specific data to widget
        updateWidget()
    }
}
