import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String text;
  
  @HiveField(2)
  final bool isUser;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final MessageType type;
  
  @HiveField(5)
  final String? audioPath;
  
  @HiveField(6)
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.audioPath,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    String? audioPath,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      audioPath: audioPath ?? this.audioPath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'audioPath': audioPath,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      audioPath: json['audioPath'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [id, text, isUser, timestamp, type, audioPath, metadata];
}

@HiveType(typeId: 1)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  voice,
  @HiveField(2)
  command,
  @HiveField(3)
  system,
  @HiveField(4)
  error,
  @HiveField(5)
  joke,
  @HiveField(6)
  whatsapp,
  @HiveField(7)
  deviceControl,
}