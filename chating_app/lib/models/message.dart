enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

class Message {
  String id;
  String senderId;
  String receiverId;
  String message;
  DateTime timestamp;
  bool isRead;
  DateTime? readAt; // Added readAt timestamp
  MessageType messageType;
  String? mediaUrl;
  Map<String, dynamic>? replyTo;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.readAt, // Added readAt parameter
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.replyTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch, // Added readAt to JSON
      'messageType': messageType.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'replyTo': replyTo,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['readAt']) : null, // Added readAt from JSON
      messageType: _getMessageType(json['messageType']),
      mediaUrl: json['mediaUrl'],
      replyTo: json['replyTo'],
    );
  }

  static MessageType _getMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt, // Added readAt parameter
    MessageType? messageType,
    String? mediaUrl,
    Map<String, dynamic>? replyTo,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt, // Added readAt to copyWith
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
