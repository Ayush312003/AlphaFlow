package com.blackmere.alphaflow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date
import android.graphics.Paint

class AlphaflowWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "AlphaflowWidget"
        const val ACTION_TOGGLE_TASK = "com.blackmere.alphaflow.TOGGLE_TASK"
        const val EXTRA_TASK_INDEX = "task_index"
        
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, AlphaflowWidgetProvider::class.java)
            )
            if (appWidgetIds.isNotEmpty()) {
                val intent = Intent(context, AlphaflowWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.alphaflow_widget)
        
        // Read custom tasks from SharedPreferences
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val customTasksJson = sharedPrefs.getString("flutter.custom_tasks", "[]")
        
        try {
            val tasksArray = JSONArray(customTasksJson)
            Log.d(TAG, "Found ${tasksArray.length()} tasks")
            
            // Always clear existing task views first
            views.removeAllViews(R.id.tasks_container)
            
            // Check if there are no tasks first
            if (tasksArray.length() == 0) {
                Log.d(TAG, "No tasks found, showing empty state")
                views.setInt(R.id.empty_state_text, "setVisibility", android.view.View.VISIBLE)
            } else {
                Log.d(TAG, "Found ${tasksArray.length()} tasks, processing them")
                views.setInt(R.id.empty_state_text, "setVisibility", android.view.View.GONE)
                // Sort tasks by priority: high -> medium -> low -> none
                val sortedTasks = mutableListOf<JSONObject>()
                for (i in 0 until tasksArray.length()) {
                    sortedTasks.add(tasksArray.getJSONObject(i))
                }
                
                sortedTasks.sortWith(compareBy<JSONObject> { task ->
                    when (task.optString("priority", "none")) {
                        "high" -> 0
                        "medium" -> 1
                        "low" -> 2
                        else -> 3
                    }
                })
                
                for (i in sortedTasks.indices) {
                    val task = sortedTasks[i]
                    val title = task.optString("title", "Unknown Task")
                    val taskId = task.optString("id", "")
                    val hasSubTasks = task.has("subTasks") && task.getJSONArray("subTasks").length() > 0
                    
                    // Determine completion status based on task type
                    val isCompleted = if (hasSubTasks) {
                        // For tasks with subtasks, check if all subtasks are completed
                        areAllSubTasksCompleted(task)
                    } else {
                        // For simple tasks, use direct isCompleted field
                        task.optBoolean("isCompleted", false)
                    }
                    
                    // Create individual task view
                    val taskViews = RemoteViews(context.packageName, R.layout.task_item)
                    // Set checkbox image based on completion status
                    val checkboxRes = if (isCompleted) R.drawable.ic_checkbox_checked else R.drawable.ic_checkbox_unchecked
                    taskViews.setImageViewResource(R.id.task_checkbox, checkboxRes)
                    taskViews.setTextViewText(R.id.task_title, title)
                    // Set strikethrough if completed
                    if (isCompleted) {
                        taskViews.setInt(R.id.task_title, "setPaintFlags", Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG)
                    } else {
                        taskViews.setInt(R.id.task_title, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                    }
                    
                    // Create click intent for this specific task
                    // Note: We need to find the original index in the unsorted array for proper toggling
                    val originalIndex = findOriginalTaskIndex(tasksArray, taskId)
                    val toggleIntent = Intent(context, AlphaflowWidgetProvider::class.java).apply {
                        action = ACTION_TOGGLE_TASK
                        putExtra(EXTRA_TASK_INDEX, originalIndex)
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val togglePendingIntent = PendingIntent.getBroadcast(
                        context, i, toggleIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    // Set click handler for this task item
                    taskViews.setOnClickPendingIntent(R.id.task_item_layout, togglePendingIntent)
                    
                    // Add task view to container
                    views.addView(R.id.tasks_container, taskViews)
                    
                    // Add separator after each task except the last one
                    if (i < sortedTasks.size - 1) {
                        val separator = RemoteViews(context.packageName, R.layout.task_separator)
                        views.addView(R.id.tasks_container, separator)
                    }
                    
                    Log.d(TAG, "Task: $title, Completed: $isCompleted, HasSubTasks: $hasSubTasks, Priority: ${task.optString("priority", "none")}")
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing tasks: ${e.message}")
            val errorViews = RemoteViews(context.packageName, R.layout.task_item)
            errorViews.setTextViewText(R.id.task_title, "Error loading tasks")
            errorViews.setTextViewText(R.id.task_checkbox, "")
            views.addView(R.id.tasks_container, errorViews)
        }
        
        // Set click handler for '+Add' button to open the app's custom tasks screen
        val addIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            action = "com.blackmere.alphaflow.OPEN_CUSTOM_TASKS"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (addIntent != null) {
            val addPendingIntent = PendingIntent.getActivity(
                context, 0, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add, addPendingIntent)
        }
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun areAllSubTasksCompleted(task: JSONObject): Boolean {
        try {
            if (!task.has("subTasks")) return false
            
            val subTasksArray = task.getJSONArray("subTasks")
            if (subTasksArray.length() == 0) return false
            
            for (i in 0 until subTasksArray.length()) {
                val subTask = subTasksArray.getJSONObject(i)
                val isCompleted = subTask.optBoolean("isCompleted", false)
                if (!isCompleted) {
                    return false
                }
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error checking subtask completion: ${e.message}")
            return false
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (appWidgetIds != null) {
                    onUpdate(context, AppWidgetManager.getInstance(context), appWidgetIds)
                }
            }
            ACTION_TOGGLE_TASK -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                
                if (taskIndex >= 0 && appWidgetId >= 0) {
                    toggleTask(context, taskIndex, appWidgetId)
                }
            }
        }
    }
    
    private fun toggleTask(context: Context, taskIndex: Int, appWidgetId: Int) {
        val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val customTasksJson = sharedPrefs.getString("flutter.custom_tasks", "[]")
        
        try {
            val tasksArray = JSONArray(customTasksJson)
            if (taskIndex < tasksArray.length()) {
                val task = tasksArray.getJSONObject(taskIndex)
                val taskId = task.optString("id", "")
                val hasSubTasks = task.has("subTasks") && task.getJSONArray("subTasks").length() > 0
                
                if (hasSubTasks) {
                    // Handle tasks with subtasks - toggle all subtasks
                    toggleSubTasksCompletion(task, tasksArray, sharedPrefs)
                } else {
                    // Handle simple tasks using direct isCompleted field
                    toggleSimpleTask(task, tasksArray, sharedPrefs)
                }
                
                // Update the widget
                updateWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error toggling task: ${e.message}")
        }
    }
    
    private fun toggleSubTasksCompletion(task: JSONObject, tasksArray: JSONArray, sharedPrefs: android.content.SharedPreferences) {
        val allSubTasksCompleted = areAllSubTasksCompleted(task)
        val newSubTaskStatus = !allSubTasksCompleted // Toggle the completion status
        
        // Update all subtasks to the new status
        if (task.has("subTasks")) {
            val subTasksArray = task.getJSONArray("subTasks")
            for (i in 0 until subTasksArray.length()) {
                val subTask = subTasksArray.getJSONObject(i)
                subTask.put("isCompleted", newSubTaskStatus)
            }
        }
        
        // Save updated tasks
        sharedPrefs.edit().putString("flutter.custom_tasks", tasksArray.toString()).apply()
        
        Log.d(TAG, "Toggled subtasks completion for task: ${task.optString("title", "Unknown")} to $newSubTaskStatus")
    }
    
    private fun toggleSimpleTask(task: JSONObject, tasksArray: JSONArray, sharedPrefs: android.content.SharedPreferences) {
        val currentCompleted = task.optBoolean("isCompleted", false)
        task.put("isCompleted", !currentCompleted)
        
        // Save updated tasks
        sharedPrefs.edit().putString("flutter.custom_tasks", tasksArray.toString()).apply()
        
        Log.d(TAG, "Toggled simple task from $currentCompleted to ${!currentCompleted}")
    }

    private fun findOriginalTaskIndex(tasksArray: JSONArray, taskId: String): Int {
        for (i in 0 until tasksArray.length()) {
            val task = tasksArray.getJSONObject(i)
            if (task.optString("id") == taskId) {
                return i
            }
        }
        return -1 // Should not happen if taskId is valid
    }
} 