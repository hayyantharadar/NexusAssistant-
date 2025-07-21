import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../models/app_settings.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _chatBoxName = 'chat_messages';
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  Box<ChatMessage>? _chatBox;
  Box<AppSettings>? _settingsBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(MessageTypeAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(ApiProviderAdapter());
    
    // Open boxes
    _chatBox = await Hive.openBox<ChatMessage>(_chatBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
  }

  // Chat Messages
  Future<void> saveChatMessage(ChatMessage message) async {
    await _chatBox?.put(message.id, message);
  }

  List<ChatMessage> getAllChatMessages() {
    return _chatBox?.values.toList() ?? [];
  }

  List<ChatMessage> getChatMessagesPaginated({int offset = 0, int limit = 50}) {
    final messages = _chatBox?.values.toList() ?? [];
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final endIndex = (offset + limit).clamp(0, messages.length);
    return messages.sublist(offset.clamp(0, messages.length), endIndex);
  }

  Future<void> deleteChatMessage(String messageId) async {
    await _chatBox?.delete(messageId);
  }

  Future<void> clearAllChatMessages() async {
    await _chatBox?.clear();
  }

  int getChatMessageCount() {
    return _chatBox?.length ?? 0;
  }

  Stream<BoxEvent> watchChatMessages() {
    return _chatBox?.watch() ?? const Stream.empty();
  }

  // Search chat messages
  List<ChatMessage> searchChatMessages(String query) {
    final messages = _chatBox?.values.toList() ?? [];
    return messages.where((message) => 
      message.text.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get messages by type
  List<ChatMessage> getChatMessagesByType(MessageType type) {
    final messages = _chatBox?.values.toList() ?? [];
    return messages.where((message) => message.type == type).toList();
  }

  // App Settings
  Future<void> saveAppSettings(AppSettings settings) async {
    await _settingsBox?.put(_settingsKey, settings);
  }

  AppSettings getAppSettings() {
    return _settingsBox?.get(_settingsKey) ?? const AppSettings();
  }

  Stream<BoxEvent> watchAppSettings() {
    return _settingsBox?.watch(key: _settingsKey) ?? const Stream.empty();
  }

  // Backup and Restore
  Future<Map<String, dynamic>> exportData() async {
    final chatMessages = getAllChatMessages();
    final settings = getAppSettings();
    
    return {
      'chatMessages': chatMessages.map((msg) => msg.toJson()).toList(),
      'settings': settings.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await clearAllChatMessages();
      
      // Import chat messages
      final chatMessagesData = data['chatMessages'] as List?;
      if (chatMessagesData != null) {
        for (final messageData in chatMessagesData) {
          final message = ChatMessage.fromJson(messageData);
          await saveChatMessage(message);
        }
      }
      
      // Import settings
      final settingsData = data['settings'] as Map<String, dynamic>?;
      if (settingsData != null) {
        final settings = AppSettings.fromJson(settingsData);
        await saveAppSettings(settings);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Database maintenance
  Future<void> compactDatabase() async {
    await _chatBox?.compact();
    await _settingsBox?.compact();
  }

  Future<void> closeDatabase() async {
    await _chatBox?.close();
    await _settingsBox?.close();
  }

  // Statistics
  Map<String, dynamic> getDatabaseStats() {
    final chatCount = getChatMessageCount();
    final userMessages = getChatMessagesByType(MessageType.text)
        .where((msg) => msg.isUser).length;
    final assistantMessages = getChatMessagesByType(MessageType.text)
        .where((msg) => !msg.isUser).length;
    final commandMessages = getChatMessagesByType(MessageType.command).length;
    final jokeMessages = getChatMessagesByType(MessageType.joke).length;
    
    return {
      'totalMessages': chatCount,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'commandMessages': commandMessages,
      'jokeMessages': jokeMessages,
      'databaseSizeKB': (_chatBox?.length ?? 0) * 0.5, // Rough estimate
    };
  }

  // Data retention
  Future<void> cleanupOldMessages({int keepDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final allMessages = getAllChatMessages();
    
    for (final message in allMessages) {
      if (message.timestamp.isBefore(cutoffDate)) {
        await deleteChatMessage(message.id);
      }
    }
  }

  // Conversation management
  Future<void> createConversationBackup() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupData = await exportData();
    
    // In a real app, you might save this to external storage
    // For now, we'll just create a backup key in settings
    final settings = getAppSettings();
    await saveAppSettings(settings.copyWith(
      // You could add backup metadata here
    ));
  }

  // Performance optimization
  Future<void> optimizeDatabase() async {
    // Remove duplicate messages
    final messages = getAllChatMessages();
    final uniqueMessages = <String, ChatMessage>{};
    
    for (final message in messages) {
      final key = '${message.text}_${message.timestamp.millisecondsSinceEpoch}';
      uniqueMessages[key] = message;
    }
    
    if (uniqueMessages.length < messages.length) {
      await clearAllChatMessages();
      for (final message in uniqueMessages.values) {
        await saveChatMessage(message);
      }
    }
    
    await compactDatabase();
  }
}