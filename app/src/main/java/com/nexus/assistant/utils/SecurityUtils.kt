package com.nexus.assistant.utils

import android.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

object SecurityUtils {
    
    private const val ALGORITHM = "AES"
    private const val TRANSFORMATION = "AES"
    private const val SECRET_KEY = "NexusAssistant2024SecretKey123"
    
    fun encrypt(data: String): String {
        return try {
            val secretKey = getSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            val encryptedData = cipher.doFinal(data.toByteArray())
            Base64.encodeToString(encryptedData, Base64.DEFAULT)
        } catch (e: Exception) {
            data // Return original data if encryption fails
        }
    }
    
    fun decrypt(encryptedData: String): String {
        return try {
            val secretKey = getSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, secretKey)
            val decodedData = Base64.decode(encryptedData, Base64.DEFAULT)
            val decryptedData = cipher.doFinal(decodedData)
            String(decryptedData)
        } catch (e: Exception) {
            encryptedData // Return original data if decryption fails
        }
    }
    
    private fun getSecretKey(): SecretKey {
        val keyBytes = SECRET_KEY.toByteArray()
        val key = ByteArray(16) // AES-128
        System.arraycopy(keyBytes, 0, key, 0, minOf(keyBytes.size, key.size))
        return SecretKeySpec(key, ALGORITHM)
    }
}

