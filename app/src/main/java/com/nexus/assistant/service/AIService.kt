package com.nexus.assistant.service

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class AIService(private val context: Context) {
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()
    
    private val prefs: SharedPreferences = context.getSharedPreferences("api_key_prefs", Context.MODE_PRIVATE)
    
    companion object {
        private const val OPENAI_BASE_URL = "https://api.openai.com/v1"
        private const val GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
        private const val DEFAULT_MODEL = "gpt-3.5-turbo"
    }
    
    suspend fun sendChatMessage(message: String, isHindi: Boolean = false): String {
        return withContext(Dispatchers.IO) {
            try {
                val apiKey = getApiKey()
                if (apiKey.isNullOrEmpty()) {
                    return@withContext "Please configure your API key first in the settings."
                }
                
                // Determine if this is an OpenAI or Gemini API key
                when {
                    apiKey.startsWith("sk-") -> sendOpenAIRequest(message, apiKey, isHindi)
                    apiKey.startsWith("AIza") -> sendGeminiRequest(message, apiKey, isHindi)
                    else -> "Invalid API key format. Please check your API key."
                }
            } catch (e: Exception) {
                "Error communicating with AI service: ${e.message}"
            }
        }
    }
    
    private suspend fun sendOpenAIRequest(message: String, apiKey: String, isHindi: Boolean): String {
        val systemPrompt = if (isHindi) {
            "You are Nexus, a helpful AI assistant. Respond in Hindi when the user speaks in Hindi, and in English otherwise. Keep responses concise and helpful."
        } else {
            "You are Nexus, a helpful AI assistant. Keep responses concise and helpful."
        }
        
        val jsonBody = JSONObject().apply {
            put("model", DEFAULT_MODEL)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", systemPrompt)
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", message)
                })
            })
            put("max_tokens", 150)
            put("temperature", 0.7)
        }
        
        val requestBody = jsonBody.toString().toRequestBody("application/json".toMediaType())
        
        val request = Request.Builder()
            .url("$OPENAI_BASE_URL/chat/completions")
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        
        return executeRequest(request)
    }
    
    private suspend fun sendGeminiRequest(message: String, apiKey: String, isHindi: Boolean): String {
        val prompt = if (isHindi) {
            "You are Nexus, a helpful AI assistant. User message: $message. Respond in Hindi if the message is in Hindi, otherwise respond in English. Keep the response concise."
        } else {
            "You are Nexus, a helpful AI assistant. User message: $message. Keep the response concise and helpful."
        }
        
        val jsonBody = JSONObject().apply {
            put("contents", JSONArray().apply {
                put(JSONObject().apply {
                    put("parts", JSONArray().apply {
                        put(JSONObject().apply {
                            put("text", prompt)
                        })
                    })
                })
            })
            put("generationConfig", JSONObject().apply {
                put("maxOutputTokens", 150)
                put("temperature", 0.7)
            })
        }
        
        val requestBody = jsonBody.toString().toRequestBody("application/json".toMediaType())
        
        val request = Request.Builder()
            .url("$GEMINI_BASE_URL/models/gemini-pro:generateContent?key=$apiKey")
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        
        return executeGeminiRequest(request)
    }
    
    private suspend fun executeRequest(request: Request): String {
        return withContext(Dispatchers.IO) {
            try {
                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()
                
                if (response.isSuccessful && responseBody != null) {
                    parseOpenAIResponse(responseBody)
                } else {
                    "API request failed: ${response.code} - ${response.message}"
                }
            } catch (e: IOException) {
                "Network error: ${e.message}"
            } catch (e: Exception) {
                "Unexpected error: ${e.message}"
            }
        }
    }
    
    private suspend fun executeGeminiRequest(request: Request): String {
        return withContext(Dispatchers.IO) {
            try {
                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()
                
                if (response.isSuccessful && responseBody != null) {
                    parseGeminiResponse(responseBody)
                } else {
                    "API request failed: ${response.code} - ${response.message}"
                }
            } catch (e: IOException) {
                "Network error: ${e.message}"
            } catch (e: Exception) {
                "Unexpected error: ${e.message}"
            }
        }
    }
    
    private fun parseOpenAIResponse(responseBody: String): String {
        return try {
            val jsonResponse = JSONObject(responseBody)
            val choices = jsonResponse.getJSONArray("choices")
            if (choices.length() > 0) {
                val firstChoice = choices.getJSONObject(0)
                val message = firstChoice.getJSONObject("message")
                message.getString("content").trim()
            } else {
                "No response received from AI service"
            }
        } catch (e: Exception) {
            "Error parsing AI response: ${e.message}"
        }
    }
    
    private fun parseGeminiResponse(responseBody: String): String {
        return try {
            val jsonResponse = JSONObject(responseBody)
            val candidates = jsonResponse.getJSONArray("candidates")
            if (candidates.length() > 0) {
                val firstCandidate = candidates.getJSONObject(0)
                val content = firstCandidate.getJSONObject("content")
                val parts = content.getJSONArray("parts")
                if (parts.length() > 0) {
                    val firstPart = parts.getJSONObject(0)
                    firstPart.getString("text").trim()
                } else {
                    "No response content received"
                }
            } else {
                "No response received from AI service"
            }
        } catch (e: Exception) {
            "Error parsing AI response: ${e.message}"
        }
    }
    
    suspend fun summarizePage(pageContent: String): String {
        val prompt = "Please provide a concise summary of the following content in 2-3 sentences:\n\n$pageContent"
        return sendChatMessage(prompt)
    }
    
    private fun getApiKey(): String? {
        val encryptedKey = prefs.getString("api_key", null)
        return if (encryptedKey != null) {
            try {
                com.nexus.assistant.utils.SecurityUtils.decrypt(encryptedKey)
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }
    }
    
    fun isApiKeyConfigured(): Boolean {
        return !getApiKey().isNullOrEmpty()
    }
}

