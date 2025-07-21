import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AIService _aiService = AIService();
  final VoiceService _voiceService = VoiceService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  Future<void> initialize() async {
    try {
      _messages = _databaseService.getAllChatMessages();
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing chat provider: $e');
    }
  }

  Future<void> sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty) return;

    try {
      // Add user message
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        type: type,
      );

      _messages.add(userMessage);
      await _databaseService.saveChatMessage(userMessage);
      notifyListeners();

      // Show typing indicator
      _isTyping = true;
      notifyListeners();

      // Get AI response
      final response = await _aiService.processCommand(text);
      await _voiceService.speak(response);

      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        type: _determineResponseType(response),
      );

      _messages.add(aiMessage);
      await _databaseService.saveChatMessage(aiMessage);
      
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  MessageType _determineResponseType(String response) {
    if (response.contains('joke') || response.contains('funny')) {
      return MessageType.joke;
    } else if (response.contains('WhatsApp')) {
      return MessageType.whatsapp;
    } else if (response.contains('flashlight') || response.contains('volume') || response.contains('brightness')) {
      return MessageType.deviceControl;
    } else if (response.contains('error') || response.contains('wrong')) {
      return MessageType.error;
    }
    return MessageType.text;
  }

  Future<void> clearMessages() async {
    try {
      await _databaseService.clearAllChatMessages();
      _messages.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing messages: $e');
    }
  }

  void searchMessages(String query) {
    if (query.isEmpty) {
      initialize();
      return;
    }
    
    _messages = _databaseService.searchChatMessages(query);
    notifyListeners();
  }
}