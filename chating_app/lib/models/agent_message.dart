import 'package:cloud_firestore/cloud_firestore.dart';

class AgentMessage {
  final String sender; // 'user' or 'agent'
  final String message;
  final DateTime timestamp;

  AgentMessage({required this.sender, required this.message, required this.timestamp});

  factory AgentMessage.fromMap(Map<String, dynamic> data) => AgentMessage(
    sender: data['sender'],
    message: data['message'],
    timestamp: (data['timestamp'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'sender': sender,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
