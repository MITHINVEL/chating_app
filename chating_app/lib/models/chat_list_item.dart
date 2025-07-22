import 'chat_user.dart';

class ChatListItem {
  String chatId;
  ChatUser otherUser;
  String lastMessage;
  DateTime lastMessageTime;
  String lastMessageSender;
  int unreadCount;
  bool isTyping;

  ChatListItem({
    required this.chatId,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSender,
    this.unreadCount = 0,
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'otherUser': otherUser.toJson(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
    };
  }

  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    return ChatListItem(
      chatId: json['chatId'] ?? '',
      otherUser: ChatUser.fromJson(json['otherUser'] ?? {}),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'] ?? 0),
      lastMessageSender: json['lastMessageSender'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isTyping: json['isTyping'] ?? false,
    );
  }

  ChatListItem copyWith({
    String? chatId,
    ChatUser? otherUser,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    int? unreadCount,
    bool? isTyping,
  }) {
    return ChatListItem(
      chatId: chatId ?? this.chatId,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
