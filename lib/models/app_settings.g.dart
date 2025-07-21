// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: fields[0] as bool,
      languageCode: fields[1] as String,
      apiKey: fields[2] as String?,
      apiProvider: fields[3] as ApiProvider,
      voiceActivationEnabled: fields[4] as bool,
      activationPhrase: fields[5] as String,
      autoStartListening: fields[6] as bool,
      voiceSensitivity: fields[7] as double,
      enableSmartLock: fields[8] as bool,
      lockPassword: fields[9] as String?,
      enableDynamicReplies: fields[10] as bool,
      maxWrongAttempts: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.apiKey)
      ..writeByte(3)
      ..write(obj.apiProvider)
      ..writeByte(4)
      ..write(obj.voiceActivationEnabled)
      ..writeByte(5)
      ..write(obj.activationPhrase)
      ..writeByte(6)
      ..write(obj.autoStartListening)
      ..writeByte(7)
      ..write(obj.voiceSensitivity)
      ..writeByte(8)
      ..write(obj.enableSmartLock)
      ..writeByte(9)
      ..write(obj.lockPassword)
      ..writeByte(10)
      ..write(obj.enableDynamicReplies)
      ..writeByte(11)
      ..write(obj.maxWrongAttempts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ApiProviderAdapter extends TypeAdapter<ApiProvider> {
  @override
  final int typeId = 3;

  @override
  ApiProvider read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ApiProvider.none;
      case 1:
        return ApiProvider.gemini;
      case 2:
        return ApiProvider.openai;
      case 3:
        return ApiProvider.custom;
      default:
        return ApiProvider.none;
    }
  }

  @override
  void write(BinaryWriter writer, ApiProvider obj) {
    switch (obj) {
      case ApiProvider.none:
        writer.writeByte(0);
        break;
      case ApiProvider.gemini:
        writer.writeByte(1);
        break;
      case ApiProvider.openai:
        writer.writeByte(2);
        break;
      case ApiProvider.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiProviderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}