import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  
  final StreamController<String> _speechController = StreamController<String>.broadcast();
  final StreamController<VoiceState> _stateController = StreamController<VoiceState>.broadcast();
  final StreamController<String> _activationController = StreamController<String>.broadcast();
  
  Stream<String> get speechStream => _speechController.stream;
  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get activationStream => _activationController.stream;
  
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request microphone permission
      final microphonePermission = await Permission.microphone.request();
      if (microphonePermission != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }
      
      // Initialize speech recognition
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          _updateState(status);
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _stateController.add(VoiceState.error);
        },
      );
      
      // Initialize TTS
      await _initializeTts();
      
      _isInitialized = true;
      _stateController.add(VoiceState.ready);
      
      return true;
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
      _stateController.add(VoiceState.error);
      return false;
    }
  }

  Future<void> _initializeTts() async {
    if (Platform.isAndroid) {
      await _flutterTts.setEngine("com.google.android.tts");
    }
    
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setLanguage("en-US");
    
    _flutterTts.setStartHandler(() {
      debugPrint('TTS Started');
    });
    
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS Completed');
    });
    
    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
    });
  }

  Future<void> startListening({
    String? language,
    Duration? timeout,
    String? activationPhrase,
  }) async {
    if (!_speechEnabled || _isListening) return;
    
    try {
      _isListening = true;
      _stateController.add(VoiceState.listening);
      
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _speechController.add(_lastWords);
          
          // Check for activation phrase
          if (activationPhrase != null && 
              _lastWords.toLowerCase().contains(activationPhrase.toLowerCase())) {
            _activationController.add(_lastWords);
          }
          
          debugPrint('Speech result: $_lastWords');
        },
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: language ?? 'en-US',
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _isListening = false;
      _stateController.add(VoiceState.error);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
      _isListening = false;
      _stateController.add(VoiceState.ready);
    } catch (e) {
      debugPrint('Error stopping listening: $e');
    }
  }

  Future<void> speak(String text, {String? language}) async {
    try {
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
  }

  Future<void> resumeSpeaking() async {
    if (Platform.isAndroid) {
      await _flutterTts.speak("");
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  List<String> getAvailableLanguages() {
    return [
      'en-US', 'en-GB', 'hi-IN', 'es-ES', 'fr-FR', 'de-DE',
      'it-IT', 'pt-BR', 'ru-RU', 'ja-JP', 'ko-KR', 'zh-CN'
    ];
  }

  void _updateState(String status) {
    switch (status) {
      case 'listening':
        _stateController.add(VoiceState.listening);
        break;
      case 'notListening':
        _isListening = false;
        _stateController.add(VoiceState.ready);
        break;
      case 'done':
        _isListening = false;
        _stateController.add(VoiceState.ready);
        break;
      default:
        break;
    }
  }

  void dispose() {
    _speechController.close();
    _stateController.close();
    _activationController.close();
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

enum VoiceState {
  idle,
  initializing,
  ready,
  listening,
  processing,
  speaking,
  error,
}