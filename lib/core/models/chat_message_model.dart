import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedTimestamp;
    try {
      if (data['timestamp'] is Timestamp) {
        parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is String) {
        parsedTimestamp = DateTime.parse(data['timestamp']);
      } else {
        parsedTimestamp = DateTime.now();
      }
    } catch (e) {
      parsedTimestamp = DateTime.now();
    }

    return ChatMessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp on write
    };
  }
}
