package com.nexus.assistant.utils

import java.util.regex.Pattern

object LanguageDetector {
    
    // Hindi Unicode ranges
    private val hindiPattern = Pattern.compile("[\\u0900-\\u097F]+")
    
    // Common Hindi words in English script
    private val hindiWordsInEnglish = setOf(
        "namaste", "dhanyawad", "kya", "hai", "hain", "mera", "tera", "uska",
        "kaise", "kahan", "kab", "kyun", "aap", "tum", "main", "hum",
        "batao", "bolo", "suno", "dekho", "karo", "jana", "aana", "jaana",
        "paani", "khana", "ghar", "kaam", "samay", "din", "raat",
        "accha", "bura", "sundar", "bada", "chota", "naya", "purana"
    )
    
    fun detectLanguage(text: String): Language {
        val cleanText = text.lowercase().trim()
        
        // Check for Hindi Unicode characters
        if (hindiPattern.matcher(text).find()) {
            return Language.HINDI
        }
        
        // Check for Hindi words written in English script
        val words = cleanText.split("\\s+".toRegex())
        val hindiWordCount = words.count { word ->
            hindiWordsInEnglish.contains(word.replace("[^a-zA-Z]".toRegex(), ""))
        }
        
        // If more than 20% of words are Hindi words, consider it Hindi
        if (words.isNotEmpty() && (hindiWordCount.toFloat() / words.size) > 0.2f) {
            return Language.HINDI
        }
        
        // Check for common Hindi phrases
        val hindiPhrases = arrayOf(
            "kya hal", "kaise ho", "kya kar rahe", "batao na", "suno na",
            "mujhe bhi", "tumhe bhi", "usse bhi", "hame bhi"
        )
        
        for (phrase in hindiPhrases) {
            if (cleanText.contains(phrase)) {
                return Language.HINDI
            }
        }
        
        return Language.ENGLISH
    }
    
    fun isHindi(text: String): Boolean {
        return detectLanguage(text) == Language.HINDI
    }
    
    fun isEnglish(text: String): Boolean {
        return detectLanguage(text) == Language.ENGLISH
    }
    
    enum class Language {
        HINDI,
        ENGLISH
    }
}

