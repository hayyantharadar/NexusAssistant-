import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  AppSettings _settings = const AppSettings();
  bool _isInitialized = false;

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  
  // Quick access properties
  bool get isDarkMode => _settings.isDarkMode;
  String get languageCode => _settings.languageCode;
  bool get voiceActivationEnabled => _settings.voiceActivationEnabled;
  String get activationPhrase => _settings.activationPhrase;
  bool get enableDynamicReplies => _settings.enableDynamicReplies;
  ApiProvider get apiProvider => _settings.apiProvider;
  String? get apiKey => _settings.apiKey;

  Future<void> initialize() async {
    try {
      _settings = _databaseService.getAppSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing app provider: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      _settings = newSettings;
      await _databaseService.saveAppSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  Future<void> toggleTheme() async {
    await updateSettings(_settings.copyWith(isDarkMode: !_settings.isDarkMode));
  }

  Future<void> changeLanguage(String languageCode) async {
    await updateSettings(_settings.copyWith(languageCode: languageCode));
  }

  Future<void> updateApiSettings({
    String? apiKey,
    ApiProvider? provider,
    bool? enableDynamicReplies,
  }) async {
    await updateSettings(_settings.copyWith(
      apiKey: apiKey,
      apiProvider: provider,
      enableDynamicReplies: enableDynamicReplies,
    ));
  }

  Future<void> updateVoiceSettings({
    bool? voiceActivationEnabled,
    String? activationPhrase,
    bool? autoStartListening,
    double? voiceSensitivity,
  }) async {
    await updateSettings(_settings.copyWith(
      voiceActivationEnabled: voiceActivationEnabled,
      activationPhrase: activationPhrase,
      autoStartListening: autoStartListening,
      voiceSensitivity: voiceSensitivity,
    ));
  }

  Future<void> updateSecuritySettings({
    bool? enableSmartLock,
    String? lockPassword,
    int? maxWrongAttempts,
  }) async {
    await updateSettings(_settings.copyWith(
      enableSmartLock: enableSmartLock,
      lockPassword: lockPassword,
      maxWrongAttempts: maxWrongAttempts,
    ));
  }
}