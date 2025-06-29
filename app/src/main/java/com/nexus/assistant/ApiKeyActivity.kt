package com.nexus.assistant

import android.Manifest
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.nexus.assistant.databinding.ActivityApiKeyBinding
import com.nexus.assistant.utils.SecurityUtils
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class ApiKeyActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityApiKeyBinding
    private lateinit var prefs: SharedPreferences
    private var wrongAttempts = 0
    private lateinit var cameraExecutor: ExecutorService
    private var imageCapture: ImageCapture? = null
    private var cameraProvider: ProcessCameraProvider? = null
    
    companion object {
        private const val PREFS_NAME = "api_key_prefs"
        private const val KEY_API_KEY = "api_key"
        private const val KEY_WRONG_ATTEMPTS = "wrong_attempts"
        private const val CORRECT_API_KEY = "NEXUS_2024_API_KEY_SECURE"
        private const val MAX_ATTEMPTS = 2
        private const val REQUEST_CAMERA_PERMISSION = 100
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityApiKeyBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        cameraExecutor = Executors.newSingleThreadExecutor()
        
        // Check if API key is already validated
        if (isApiKeyValid()) {
            navigateToMain()
            return
        }
        
        wrongAttempts = prefs.getInt(KEY_WRONG_ATTEMPTS, 0)
        
        setupUI()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            setupCamera()
        } else {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
        }
    }
    
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                setupCamera()
            } else {
                // Camera permission denied, photo capture won't work
            }
        }
    }
    
    private fun setupUI() {
        binding.btnContinue.setOnClickListener {
            validateApiKey()
        }
        
        binding.etApiKey.setOnEditorActionListener { _, _, _ ->
            validateApiKey()
            true
        }
    }
    
    private fun setupCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            
            val preview = Preview.Builder().build()
            imageCapture = ImageCapture.Builder().build()
            
            // Try front camera first, then back camera
            val cameraSelector = when {
                hasFrontCamera() -> CameraSelector.DEFAULT_FRONT_CAMERA
                hasBackCamera() -> CameraSelector.DEFAULT_BACK_CAMERA
                else -> null
            }
            
            if (cameraSelector != null) {
                try {
                    cameraProvider?.unbindAll()
                    cameraProvider?.bindToLifecycle(
                        this, cameraSelector, preview, imageCapture
                    )
                } catch (exc: Exception) {
                    // Camera setup failed
                }
            } else {
                // No camera available
            }
        }, ContextCompat.getMainExecutor(this))
    }
    
    private fun hasFrontCamera(): Boolean {
        return packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)
    }
    
    private fun hasBackCamera(): Boolean {
        return packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
    }
    
    private fun validateApiKey() {
        val enteredKey = binding.etApiKey.text.toString().trim()
        
        if (enteredKey == CORRECT_API_KEY) {
            // Correct API key
            saveApiKey(enteredKey)
            resetWrongAttempts()
            navigateToMain()
        } else {
            // Wrong API key
            wrongAttempts++
            saveWrongAttempts()
            
            when (wrongAttempts) {
                1 -> {
                    showError(getString(R.string.wrong_password))
                }
                2 -> {
                    showError(getString(R.string.wrong_password_again))
                    captureIntruderPhoto()
                }
                else -> {
                    showError(getString(R.string.wrong_password))
                    captureIntruderPhoto()
                }
            }
            
            binding.etApiKey.text?.clear()
        }
    }
    
    private fun captureIntruderPhoto() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            // Camera permission not granted, cannot capture photo
            return
        }
        
        val imageCapture = imageCapture ?: return
        
        val outputDirectory = getOutputDirectory()
        if (!outputDirectory.exists()) outputDirectory.mkdirs()
        
        val photoFile = File(
            outputDirectory,
            SimpleDateFormat("yyyy-MM-dd-HH-mm-ss-SSS", Locale.US).format(System.currentTimeMillis()) + ".jpg"
        )
        
        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(this),
            object : ImageCapture.OnImageSavedCallback {
                override fun onError(exc: ImageCaptureException) {
                    // Photo capture failed silently
                }
                
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    // Photo captured successfully silently
                }
            }
        )
    }
    
    private fun getOutputDirectory(): File {
        val mediaDir = externalMediaDirs.firstOrNull()?.let {
            File(it, "NexusSecurity/Intruders").apply { mkdirs() }
        }
        return if (mediaDir != null && mediaDir.exists()) mediaDir else filesDir
    }
    
    private fun showError(message: String) {
        binding.tvError.text = message
        binding.tvError.visibility = android.view.View.VISIBLE
        
        // Hide error after 3 seconds
        binding.tvError.postDelayed({
            binding.tvError.visibility = android.view.View.GONE
        }, 3000)
    }
    
    private fun saveApiKey(apiKey: String) {
        prefs.edit()
            .putString(KEY_API_KEY, SecurityUtils.encrypt(apiKey))
            .apply()
    }
    
    private fun saveWrongAttempts() {
        prefs.edit()
            .putInt(KEY_WRONG_ATTEMPTS, wrongAttempts)
            .apply()
    }
    
    private fun resetWrongAttempts() {
        prefs.edit()
            .putInt(KEY_WRONG_ATTEMPTS, 0)
            .apply()
    }
    
    private fun isApiKeyValid(): Boolean {
        val savedKey = prefs.getString(KEY_API_KEY, null)
        return savedKey != null && SecurityUtils.decrypt(savedKey) == CORRECT_API_KEY
    }
    
    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        startActivity(intent)
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        cameraProvider?.unbindAll()
    }
}

