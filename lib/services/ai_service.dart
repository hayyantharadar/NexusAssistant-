import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  AppSettings? _settings;
  final Random _random = Random();

  void updateSettings(AppSettings settings) {
    _settings = settings;
  }

  Future<String> processCommand(String input) async {
    if (_settings == null) {
      return "I'm not properly configured yet. Please check settings.";
    }

    final cleanInput = input.toLowerCase().trim();
    
    try {
      // Check for specific command patterns first
      final response = await _handleSpecificCommands(cleanInput);
      if (response != null) return response;

      // If AI is enabled and API key is available, use online AI
      if (_settings!.enableDynamicReplies && 
          _settings!.apiKey != null && 
          _settings!.apiKey!.isNotEmpty) {
        return await _getAIResponse(input);
      }

      // Fall back to offline responses
      return _getOfflineResponse(cleanInput);
    } catch (e) {
      debugPrint('Error processing command: $e');
      return _getErrorResponse();
    }
  }

  Future<String?> _handleSpecificCommands(String input) async {
    // WhatsApp commands
    if (input.contains('send whatsapp') || input.contains('whatsapp message')) {
      return _handleWhatsAppCommand(input);
    }
    
    // Device control commands
    if (input.contains('turn on') || input.contains('turn off')) {
      return _handleDeviceControl(input);
    }
    
    // App opening commands
    if (input.contains('open')) {
      return _handleAppOpen(input);
    }
    
    // Joke commands
    if (input.contains('joke') || input.contains('funny')) {
      return _getJoke();
    }
    
    // Battery/System info
    if (input.contains('battery') || input.contains('system')) {
      return _getSystemInfo(input);
    }
    
    // Screen analysis
    if (input.contains('analyze screen') || input.contains('what do you see')) {
      return "I would analyze the screen content here. This feature requires camera integration.";
    }
    
    return null;
  }

  String _handleWhatsAppCommand(String input) {
    if (input.contains('to')) {
      final parts = input.split('to');
      if (parts.length >= 2) {
        final recipient = parts[1].trim();
        return "I'll send a WhatsApp message to $recipient. Please specify the message content.";
      }
    }
    return "Please specify who you want to send a WhatsApp message to and what message.";
  }

  String _handleDeviceControl(String input) {
    if (input.contains('flashlight') || input.contains('torch')) {
      if (input.contains('turn on')) {
        return "Turning on the flashlight.";
      } else {
        return "Turning off the flashlight.";
      }
    }
    
    if (input.contains('wifi')) {
      if (input.contains('turn on')) {
        return "Turning on WiFi.";
      } else {
        return "Turning off WiFi.";
      }
    }
    
    if (input.contains('volume')) {
      if (input.contains('up') || input.contains('increase')) {
        return "Increasing volume.";
      } else if (input.contains('down') || input.contains('decrease')) {
        return "Decreasing volume.";
      }
    }
    
    if (input.contains('brightness')) {
      if (input.contains('up') || input.contains('increase')) {
        return "Increasing screen brightness.";
      } else if (input.contains('down') || input.contains('decrease')) {
        return "Decreasing screen brightness.";
      }
    }
    
    return "I can help control your device. Try commands like 'turn on flashlight' or 'increase volume'.";
  }

  String _handleAppOpen(String input) {
    final apps = {
      'camera': 'Opening Camera app.',
      'gallery': 'Opening Gallery app.',
      'settings': 'Opening Settings app.',
      'contacts': 'Opening Contacts app.',
      'phone': 'Opening Phone app.',
      'messages': 'Opening Messages app.',
      'browser': 'Opening Browser app.',
      'calculator': 'Opening Calculator app.',
      'calendar': 'Opening Calendar app.',
      'music': 'Opening Music app.',
    };
    
    for (final app in apps.keys) {
      if (input.contains(app)) {
        return apps[app]!;
      }
    }
    
    return "I can help you open apps. Try saying 'open camera' or 'open settings'.";
  }

  String _getJoke() {
    final jokes = [
      "Why don't scientists trust atoms? Because they make up everything!",
      "Why did the scarecrow win an award? He was outstanding in his field!",
      "Why don't eggs tell jokes? They'd crack each other up!",
      "What do you call a fake noodle? An impasta!",
      "Why did the coffee file a police report? It got mugged!",
      "What do you call a bear with no teeth? A gummy bear!",
      "Why don't skeletons fight each other? They don't have the guts!",
      "What do you call a sleeping bull? A bulldozer!",
      "Why did the math book look so sad? Because it had too many problems!",
      "What do you call a dinosaur that crashes his car? Tyrannosaurus Wrecks!",
    ];
    
    return jokes[_random.nextInt(jokes.length)];
  }

  String _getSystemInfo(String input) {
    if (input.contains('battery')) {
      return "Your battery level is 78% and charging. Would you like more details?";
    }
    return "System is running normally. All services are active.";
  }

  Future<String> _getAIResponse(String input) async {
    try {
      switch (_settings!.apiProvider) {
        case ApiProvider.gemini:
          return await _getGeminiResponse(input);
        case ApiProvider.openai:
          return await _getOpenAIResponse(input);
        case ApiProvider.custom:
          return await _getCustomAIResponse(input);
        default:
          return _getOfflineResponse(input);
      }
    } catch (e) {
      debugPrint('AI API error: $e');
      return _getOfflineResponse(input);
    }
  }

  Future<String> _getGeminiResponse(String input) async {
    const baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';
    final url = '$baseUrl?key=${_settings!.apiKey}';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{
          'parts': [{'text': input}]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 150,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? _getOfflineResponse(input);
        }
      }
    }
    
    throw Exception('Failed to get Gemini response');
  }

  Future<String> _getOpenAIResponse(String input) async {
    const url = 'https://api.openai.com/v1/chat/completions';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_settings!.apiKey}',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are Nexus, a helpful voice assistant.'},
          {'role': 'user', 'content': input}
        ],
        'max_tokens': 150,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']['content'] ?? _getOfflineResponse(input);
      }
    }
    
    throw Exception('Failed to get OpenAI response');
  }

  Future<String> _getCustomAIResponse(String input) async {
    // Placeholder for custom AI implementation
    return _getOfflineResponse(input);
  }

  String _getOfflineResponse(String input) {
    // Greeting responses
    if (_isGreeting(input)) {
      return _getGreetingResponse();
    }
    
    // Question responses
    if (_isQuestion(input)) {
      return _getQuestionResponse(input);
    }
    
    // Compliment responses
    if (_isCompliment(input)) {
      return _getComplimentResponse();
    }
    
    // Default responses
    return _getDefaultResponse();
  }

  bool _isGreeting(String input) {
    final greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'];
    return greetings.any((greeting) => input.contains(greeting));
  }

  bool _isQuestion(String input) {
    final questionWords = ['what', 'how', 'when', 'where', 'why', 'who', 'which'];
    return questionWords.any((word) => input.startsWith(word)) || input.endsWith('?');
  }

  bool _isCompliment(String input) {
    final compliments = ['thank you', 'thanks', 'good job', 'well done', 'awesome', 'great'];
    return compliments.any((compliment) => input.contains(compliment));
  }

  String _getGreetingResponse() {
    final responses = [
      "Hello! I'm Nexus, your personal assistant. How can I help you today?",
      "Hi there! Ready to assist you with anything you need.",
      "Good to see you! What would you like me to help you with?",
      "Hello! I'm here to make your day easier. What can I do for you?",
    ];
    return responses[_random.nextInt(responses.length)];
  }

  String _getQuestionResponse(String input) {
    if (input.contains('time')) {
      return "The current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.";
    }
    
    if (input.contains('weather')) {
      return "I don't have access to weather data right now, but you can ask me to open a weather app.";
    }
    
    if (input.contains('name')) {
      return "I'm Nexus, your intelligent voice assistant.";
    }
    
    return "That's an interesting question. I'm still learning and improving my knowledge base.";
  }

  String _getComplimentResponse() {
    final responses = [
      "You're welcome! Happy to help anytime.",
      "My pleasure! That's what I'm here for.",
      "Glad I could assist you!",
      "You're very welcome! Let me know if you need anything else.",
    ];
    return responses[_random.nextInt(responses.length)];
  }

  String _getDefaultResponse() {
    final responses = [
      "I'm not sure I understand. Could you try rephrasing that?",
      "I'm still learning. Can you help me understand what you need?",
      "That's interesting! I'm working on understanding more commands like that.",
      "I didn't quite catch that. Could you say it differently?",
      "I'm here to help! Try asking me about device controls, apps, or general questions.",
    ];
    return responses[_random.nextInt(responses.length)];
  }

  String _getErrorResponse() {
    final responses = [
      "Sorry, I encountered an error. Please try again.",
      "Something went wrong. Let me try to help you differently.",
      "I had a problem processing that. Could you repeat your request?",
    ];
    return responses[_random.nextInt(responses.length)];
  }
}