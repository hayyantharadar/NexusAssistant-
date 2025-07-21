import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();

  VoiceState _state = VoiceState.idle;
  String _recognizedText = '';
  bool _isListening = false;

  VoiceState get state => _state;
  String get recognizedText => _recognizedText;
  bool get isListening => _isListening;

  Future<void> initialize() async {
    try {
      await _voiceService.initialize();
      
      _voiceService.stateStream.listen((state) {
        _state = state;
        _isListening = state == VoiceState.listening;
        notifyListeners();
      });

      _voiceService.speechStream.listen((text) {
        _recognizedText = text;
        notifyListeners();
      });

    } catch (e) {
      debugPrint('Error initializing voice provider: $e');
    }
  }

  Future<void> startListening() async {
    try {
      await _voiceService.startListening();
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _voiceService.stopListening();
    } catch (e) {
      debugPrint('Error stopping voice recognition: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      await _voiceService.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  void clearRecognizedText() {
    _recognizedText = '';
    notifyListeners();
  }
}