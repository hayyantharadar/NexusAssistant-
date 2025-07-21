import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends Equatable {
  @HiveField(0)
  final bool isDarkMode;
  
  @HiveField(1)
  final String languageCode;
  
  @HiveField(2)
  final String? apiKey;
  
  @HiveField(3)
  final ApiProvider apiProvider;
  
  @HiveField(4)
  final bool voiceActivationEnabled;
  
  @HiveField(5)
  final String activationPhrase;
  
  @HiveField(6)
  final bool autoStartListening;
  
  @HiveField(7)
  final double voiceSensitivity;
  
  @HiveField(8)
  final bool enableSmartLock;
  
  @HiveField(9)
  final String? lockPassword;
  
  @HiveField(10)
  final bool enableDynamicReplies;
  
  @HiveField(11)
  final int maxWrongAttempts;

  const AppSettings({
    this.isDarkMode = false,
    this.languageCode = 'en',
    this.apiKey,
    this.apiProvider = ApiProvider.none,
    this.voiceActivationEnabled = true,
    this.activationPhrase = 'Nexus',
    this.autoStartListening = true,
    this.voiceSensitivity = 0.7,
    this.enableSmartLock = false,
    this.lockPassword,
    this.enableDynamicReplies = false,
    this.maxWrongAttempts = 3,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? languageCode,
    String? apiKey,
    ApiProvider? apiProvider,
    bool? voiceActivationEnabled,
    String? activationPhrase,
    bool? autoStartListening,
    double? voiceSensitivity,
    bool? enableSmartLock,
    String? lockPassword,
    bool? enableDynamicReplies,
    int? maxWrongAttempts,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      apiKey: apiKey ?? this.apiKey,
      apiProvider: apiProvider ?? this.apiProvider,
      voiceActivationEnabled: voiceActivationEnabled ?? this.voiceActivationEnabled,
      activationPhrase: activationPhrase ?? this.activationPhrase,
      autoStartListening: autoStartListening ?? this.autoStartListening,
      voiceSensitivity: voiceSensitivity ?? this.voiceSensitivity,
      enableSmartLock: enableSmartLock ?? this.enableSmartLock,
      lockPassword: lockPassword ?? this.lockPassword,
      enableDynamicReplies: enableDynamicReplies ?? this.enableDynamicReplies,
      maxWrongAttempts: maxWrongAttempts ?? this.maxWrongAttempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'languageCode': languageCode,
      'apiKey': apiKey,
      'apiProvider': apiProvider.name,
      'voiceActivationEnabled': voiceActivationEnabled,
      'activationPhrase': activationPhrase,
      'autoStartListening': autoStartListening,
      'voiceSensitivity': voiceSensitivity,
      'enableSmartLock': enableSmartLock,
      'lockPassword': lockPassword,
      'enableDynamicReplies': enableDynamicReplies,
      'maxWrongAttempts': maxWrongAttempts,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      languageCode: json['languageCode'] ?? 'en',
      apiKey: json['apiKey'],
      apiProvider: ApiProvider.values.firstWhere(
        (e) => e.name == json['apiProvider'],
        orElse: () => ApiProvider.none,
      ),
      voiceActivationEnabled: json['voiceActivationEnabled'] ?? true,
      activationPhrase: json['activationPhrase'] ?? 'Nexus',
      autoStartListening: json['autoStartListening'] ?? true,
      voiceSensitivity: json['voiceSensitivity']?.toDouble() ?? 0.7,
      enableSmartLock: json['enableSmartLock'] ?? false,
      lockPassword: json['lockPassword'],
      enableDynamicReplies: json['enableDynamicReplies'] ?? false,
      maxWrongAttempts: json['maxWrongAttempts'] ?? 3,
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        languageCode,
        apiKey,
        apiProvider,
        voiceActivationEnabled,
        activationPhrase,
        autoStartListening,
        voiceSensitivity,
        enableSmartLock,
        lockPassword,
        enableDynamicReplies,
        maxWrongAttempts,
      ];
}

@HiveType(typeId: 3)
enum ApiProvider {
  @HiveField(0)
  none,
  @HiveField(1)
  gemini,
  @HiveField(2)
  openai,
  @HiveField(3)
  custom,
}