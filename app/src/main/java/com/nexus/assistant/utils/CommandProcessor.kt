package com.nexus.assistant.utils

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import com.nexus.assistant.R
import com.nexus.assistant.receiver.DeviceAdminReceiver
import com.nexus.assistant.service.AIService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.*

class CommandProcessor(private val context: Context) {
    
    private val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val adminComponent = ComponentName(context, DeviceAdminReceiver::class.java)
    private val aiService = AIService(context)
    
    private var isFlashlightOn = false
    
    fun processCommand(command: String, callback: (String) -> Unit) {
        val lowerCommand = command.lowercase().trim()
        
        when {
            // WhatsApp commands
            lowerCommand.contains("whatsapp") || lowerCommand.contains("message") -> {
                callback(handleWhatsAppCommand(lowerCommand))
            }
            
            // App opening commands
            lowerCommand.contains("open") -> {
                callback(handleOpenAppCommand(lowerCommand))
            }
            
            // Wi-Fi commands
            lowerCommand.contains("wifi") || lowerCommand.contains("wi-fi") -> {
                callback(handleWifiCommand(lowerCommand))
            }
            
            // Flashlight commands
            lowerCommand.contains("flashlight") || lowerCommand.contains("torch") || lowerCommand.contains("light") -> {
                callback(handleFlashlightCommand(lowerCommand))
            }
            
            // Screen lock commands
            lowerCommand.contains("lock") && lowerCommand.contains("screen") -> {
                callback(handleScreenLockCommand())
            }
            
            // Joke commands
            lowerCommand.contains("joke") || lowerCommand.contains("funny") -> {
                callback(getRandomJoke())
            }
            
            // Weather commands
            lowerCommand.contains("weather") -> {
                callback(handleWeatherCommand())
            }
            
            // Page summarization
            lowerCommand.contains("summarize") -> {
                handleSummarizeCommand(callback)
            }
            
            // AI Chat - General queries
            else -> {
                handleAIChat(command, callback)
            }
        }
    }
    
    private fun handleAIChat(command: String, callback: (String) -> Unit) {
        if (!aiService.isApiKeyConfigured()) {
            callback("Please configure your API key first to use AI chat features.")
            return
        }
        
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val isHindi = LanguageDetector.isHindi(command)
                val response = aiService.sendChatMessage(command, isHindi)
                callback(response)
            } catch (e: Exception) {
                callback("Error processing AI request: ${e.message}")
            }
        }
    }
    
    private fun handleSummarizeCommand(callback: (String) -> Unit) {
        if (!aiService.isApiKeyConfigured()) {
            callback("Please configure your API key first to use page summarization.")
            return
        }
        
        // In a real implementation, this would get the current page content
        // For now, we'll provide a placeholder response
        callback("Page summarization requires screen content access. This feature will analyze the current screen content and provide a summary.")
    }
    
    private fun handleWhatsAppCommand(command: String): String {
        return try {
            // Check if WhatsApp is installed
            val packageManager = context.packageManager
            packageManager.getPackageInfo("com.whatsapp", PackageManager.GET_ACTIVITIES)
            
            // Extract contact name or number from command
            val contact = extractContactFromCommand(command)
            
            if (contact.isNotEmpty()) {
                // Open WhatsApp with specific contact
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("https://api.whatsapp.com/send?phone=$contact")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                "Opening WhatsApp to send message to $contact"
            } else {
                // Open WhatsApp main screen
                val intent = packageManager.getLaunchIntentForPackage("com.whatsapp")
                intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                "Opening WhatsApp"
            }
        } catch (e: PackageManager.NameNotFoundException) {
            "WhatsApp is not installed on this device"
        } catch (e: Exception) {
            "Failed to open WhatsApp: ${e.message}"
        }
    }
    
    private fun extractContactFromCommand(command: String): String {
        // Simple extraction - in a real app, this would be more sophisticated
        val words = command.split(" ")
        val toIndex = words.indexOfFirst { it.contains("to") }
        
        if (toIndex != -1 && toIndex < words.size - 1) {
            return words.subList(toIndex + 1, words.size).joinToString(" ")
        }
        
        return ""
    }
    
    private fun handleOpenAppCommand(command: String): String {
        val appName = extractAppNameFromCommand(command)
        
        return when (appName.lowercase()) {
            "youtube" -> openApp("com.google.android.youtube", "YouTube")
            "chrome" -> openApp("com.android.chrome", "Chrome")
            "whatsapp" -> openApp("com.whatsapp", "WhatsApp")
            "instagram" -> openApp("com.instagram.android", "Instagram")
            "facebook" -> openApp("com.facebook.katana", "Facebook")
            "twitter" -> openApp("com.twitter.android", "Twitter")
            "gmail" -> openApp("com.google.android.gm", "Gmail")
            "maps" -> openApp("com.google.android.apps.maps", "Google Maps")
            "camera" -> openApp("com.android.camera2", "Camera")
            "gallery" -> openApp("com.google.android.apps.photos", "Photos")
            "settings" -> {
                val intent = Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                "Opening Settings"
            }
            else -> "I couldn't find the app '$appName'. Please make sure it's installed."
        }
    }
    
    private fun extractAppNameFromCommand(command: String): String {
        val words = command.split(" ")
        val openIndex = words.indexOfFirst { it.contains("open") }
        
        if (openIndex != -1 && openIndex < words.size - 1) {
            return words.subList(openIndex + 1, words.size).joinToString(" ")
        }
        
        return ""
    }
    
    private fun openApp(packageName: String, appName: String): String {
        return try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                "Opening $appName"
            } else {
                "$appName is not installed on this device"
            }
        } catch (e: Exception) {
            "Failed to open $appName: ${e.message}"
        }
    }
    
    private fun handleWifiCommand(command: String): String {
        return try {
            when {
                command.contains("on") || command.contains("enable") -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        // Android 10+ requires user to manually enable Wi-Fi
                        val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        "Please enable Wi-Fi manually in settings"
                    } else {
                        @Suppress("DEPRECATION")
                        wifiManager.isWifiEnabled = true
                        "Wi-Fi enabled"
                    }
                }
                command.contains("off") || command.contains("disable") -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                        "Please disable Wi-Fi manually in settings"
                    } else {
                        @Suppress("DEPRECATION")
                        wifiManager.isWifiEnabled = false
                        "Wi-Fi disabled"
                    }
                }
                else -> {
                    val isEnabled = wifiManager.isWifiEnabled
                    "Wi-Fi is currently ${if (isEnabled) "enabled" else "disabled"}"
                }
            }
        } catch (e: Exception) {
            "Failed to control Wi-Fi: ${e.message}"
        }
    }
    
    private fun handleFlashlightCommand(command: String): String {
        return try {
            when {
                command.contains("on") || command.contains("enable") -> {
                    toggleFlashlight(true)
                    isFlashlightOn = true
                    "Flashlight turned on"
                }
                command.contains("off") || command.contains("disable") -> {
                    toggleFlashlight(false)
                    isFlashlightOn = false
                    "Flashlight turned off"
                }
                else -> {
                    isFlashlightOn = !isFlashlightOn
                    toggleFlashlight(isFlashlightOn)
                    if (isFlashlightOn) "Flashlight turned on" else "Flashlight turned off"
                }
            }
        } catch (e: Exception) {
            "Failed to control flashlight: ${e.message}"
        }
    }
    
    private fun toggleFlashlight(enable: Boolean) {
        try {
            val cameraId = cameraManager.cameraIdList[0]
            cameraManager.setTorchMode(cameraId, enable)
        } catch (e: CameraAccessException) {
            throw Exception("Camera access denied")
        }
    }
    
    private fun handleScreenLockCommand(): String {
        return try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.lockNow()
                "Screen locked"
            } else {
                // Request device admin permission
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                        "Enable device admin to allow screen locking")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                "Please enable device admin permission to lock screen"
            }
        } catch (e: Exception) {
            "Failed to lock screen: ${e.message}"
        }
    }
    
    private fun getRandomJoke(): String {
        val jokes = arrayOf(
            "Why don't scientists trust atoms? Because they make up everything!",
            "Why did the scarecrow win an award? He was outstanding in his field!",
            "Why don't eggs tell jokes? They'd crack each other up!",
            "What do you call a fake noodle? An impasta!",
            "Why did the math book look so sad? Because it had too many problems!",
            "What do you call a bear with no teeth? A gummy bear!",
            "Why don't programmers like nature? It has too many bugs!",
            "What's the best thing about Switzerland? I don't know, but the flag is a big plus!",
            "Why did the coffee file a police report? It got mugged!",
            "What do you call a dinosaur that crashes his car? Tyrannosaurus Wrecks!"
        )
        
        return jokes[Random().nextInt(jokes.size)]
    }
    
    private fun handleWeatherCommand(): String {
        // In a real app, this would integrate with a weather API
        return "Weather information requires internet connection and API integration. " +
                "Current feature shows placeholder data. Today's weather: Partly cloudy, 22°C."
    }
}

