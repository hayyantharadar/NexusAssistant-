package com.nexus.assistant

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.GridLayoutManager
import com.nexus.assistant.adapter.CommandAdapter
import com.nexus.assistant.databinding.ActivityMainBinding
import com.nexus.assistant.model.Command
import com.nexus.assistant.service.VoiceService
import com.nexus.assistant.utils.CommandProcessor
import com.nexus.assistant.utils.VoiceAnimationUtils
import java.util.*

class MainActivity : AppCompatActivity(), TextToSpeech.OnInitListener {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var speechRecognizer: SpeechRecognizer
    private lateinit var textToSpeech: TextToSpeech
    private lateinit var commandProcessor: CommandProcessor
    private lateinit var commandAdapter: CommandAdapter
    private var isListening = false
    private var isTTSReady = false
    
    companion object {
        private const val REQUEST_RECORD_AUDIO_PERMISSION = 200
        private const val REQUEST_CAMERA_PERMISSION = 201
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        initializeComponents()
        setupUI()
        checkPermissions()
    }
    
    private fun initializeComponents() {
        textToSpeech = TextToSpeech(this, this)
        commandProcessor = CommandProcessor(this)
        
        // Initialize speech recognizer
        if (SpeechRecognizer.isRecognitionAvailable(this)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer.setRecognitionListener(speechRecognitionListener)
        }
    }
    
    private fun setupUI() {
        // Setup RecyclerView for commands
        commandAdapter = CommandAdapter(getQuickCommands()) { command ->
            executeCommand(command.title)
        }
        
        binding.rvCommands.apply {
            layoutManager = GridLayoutManager(this@MainActivity, 2)
            adapter = commandAdapter
        }
        
        // Setup microphone button
        binding.fabMicrophone.setOnClickListener {
            if (isListening) {
                stopListening()
            } else {
                startListening()
            }
        }
        
        // Setup settings button
        binding.btnSettings.setOnClickListener {
            // Open settings (placeholder)
            Toast.makeText(this, "Settings", Toast.LENGTH_SHORT).show()
        }
        
        // Start voice service for wake word detection
        startVoiceService()
    }
    
    private fun getQuickCommands(): List<Command> {
        return listOf(
            Command("WhatsApp", "Send message", R.drawable.ic_whatsapp),
            Command("Open Apps", "Launch app", R.drawable.ic_apps),
            Command("Wi-Fi", "Toggle Wi-Fi", R.drawable.ic_settings),
            Command("Flashlight", "Toggle light", R.drawable.ic_settings),
            Command("Weather", "Get weather", R.drawable.ic_settings),
            Command("Joke", "Tell a joke", R.drawable.ic_settings)
        )
    }
    
    private fun checkPermissions() {
        val permissions = mutableListOf<String>()
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.RECORD_AUDIO)
        }
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
            != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.CAMERA)
        }
        
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), REQUEST_RECORD_AUDIO_PERMISSION)
        }
    }
    
    private fun startListening() {
        if (!::speechRecognizer.isInitialized) {
            Toast.makeText(this, "Speech recognition not available", Toast.LENGTH_SHORT).show()
            return
        }
        
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        
        isListening = true
        updateUI()
        speechRecognizer.startListening(intent)
        VoiceAnimationUtils.startWaveAnimation(binding.llWaveform)
    }
    
    private fun stopListening() {
        if (::speechRecognizer.isInitialized) {
            speechRecognizer.stopListening()
        }
        isListening = false
        updateUI()
        VoiceAnimationUtils.stopWaveAnimation(binding.llWaveform)
    }
    
    private fun updateUI() {
        if (isListening) {
            binding.tvStatus.text = getString(R.string.listening)
            binding.fabMicrophone.setImageResource(R.drawable.ic_microphone)
            binding.tvWaveformPlaceholder.visibility = android.view.View.GONE
        } else {
            binding.tvStatus.text = getString(R.string.tap_to_speak)
            binding.fabMicrophone.setImageResource(R.drawable.ic_microphone)
            binding.tvWaveformPlaceholder.visibility = android.view.View.VISIBLE
        }
    }
    
    private val speechRecognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            binding.tvStatus.text = getString(R.string.speak_now)
        }
        
        override fun onBeginningOfSpeech() {
            binding.tvStatus.text = getString(R.string.listening)
        }
        
        override fun onRmsChanged(rmsdB: Float) {
            // Update voice animation based on volume
            VoiceAnimationUtils.updateWaveAnimation(binding.llWaveform, rmsdB)
        }
        
        override fun onBufferReceived(buffer: ByteArray?) {}
        
        override fun onEndOfSpeech() {
            binding.tvStatus.text = getString(R.string.processing)
        }
        
        override fun onError(error: Int) {
            isListening = false
            updateUI()
            
            val errorMessage = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                SpeechRecognizer.ERROR_NETWORK -> "Network error"
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                SpeechRecognizer.ERROR_NO_MATCH -> "No speech input"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                SpeechRecognizer.ERROR_SERVER -> "Server error"
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                else -> "Unknown error"
            }
            
            if (error != SpeechRecognizer.ERROR_NO_MATCH && error != SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                Toast.makeText(this@MainActivity, errorMessage, Toast.LENGTH_SHORT).show()
            }
        }
        
        override fun onResults(results: Bundle?) {
            isListening = false
            updateUI()
            
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (!matches.isNullOrEmpty()) {
                val spokenText = matches[0]
                processVoiceCommand(spokenText)
            }
        }
        
        override fun onPartialResults(partialResults: Bundle?) {
            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (!matches.isNullOrEmpty()) {
                binding.tvStatus.text = "\"${matches[0]}\""
            }
        }
        
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }
    
    private fun processVoiceCommand(command: String) {
        // Check for wake words first
        val lowerCommand = command.lowercase()
        if (lowerCommand.contains("nexus") || lowerCommand.contains("n x s")) {
            // Wake word detected, process the rest of the command
            val actualCommand = lowerCommand.replace("nexus", "").replace("n x s", "").trim()
            if (actualCommand.isNotEmpty()) {
                executeCommand(actualCommand)
            } else {
                speak("Yes, how can I help you?")
                showResponse("Nexus Assistant", "I'm listening. How can I help you?")
            }
        } else {
            // Direct command without wake word
            executeCommand(command)
        }
    }
    
    private fun executeCommand(command: String) {
        binding.tvStatus.text = "Processing..."
        commandProcessor.processCommand(command) { response ->
            runOnUiThread {
                showResponse("Command Result", response)
                speak(response)
                binding.tvStatus.text = getString(R.string.tap_to_speak)
            }
        }
    }
    
    private fun showResponse(title: String, response: String) {
        binding.cardResponse.visibility = android.view.View.VISIBLE
        binding.tvResponseTitle.text = title
        binding.tvResponse.text = response
    }
    
    private fun speak(text: String) {
        if (isTTSReady) {
            textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        }
    }
    
    private fun startVoiceService() {
        val serviceIntent = Intent(this, VoiceService::class.java)
        startForegroundService(serviceIntent)
    }
    
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = textToSpeech.setLanguage(Locale.getDefault())
            isTTSReady = result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED
            
            if (!isTTSReady) {
                Toast.makeText(this, "TTS language not supported", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            REQUEST_RECORD_AUDIO_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Permission granted
                } else {
                    Toast.makeText(this, getString(R.string.microphone_permission), Toast.LENGTH_LONG).show()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (::speechRecognizer.isInitialized) {
            speechRecognizer.destroy()
        }
        if (::textToSpeech.isInitialized) {
            textToSpeech.stop()
            textToSpeech.shutdown()
        }
    }
}

