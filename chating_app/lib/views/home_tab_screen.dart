import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class HomeTabScreen extends StatefulWidget {
  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final ChatController chatController = Get.put(ChatController());
  final String currentUserId = 'demoUserId'; // TODO: Replace with actual userId from auth

  @override
  void initState() {
    super.initState();
    chatController.fetchChats(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.indigo,
      ),
      body: Obx(() {
        if (chatController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (chatController.chats.isEmpty) {
          return Center(child: Text('No chats yet'));
        }
        return ListView.builder(
          itemCount: chatController.chats.length,
          itemBuilder: (context, idx) {
            final chat = chatController.chats[idx];
            final String otherUserId = chat.members.firstWhere((id) => id != currentUserId, orElse: () => '');
            return ListTile(
              leading: Hero(
                tag: 'profile_$otherUserId',
                child: CircleAvatar(child: Text(otherUserId.isNotEmpty ? otherUserId[0] : '?')),
              ),
              title: Text('User: $otherUserId'),
              subtitle: Text(chat.lastMessage),
              trailing: _buildUnreadIndicator(chat),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chat.chatId,
                      otherUserId: otherUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildUnreadIndicator(ChatModel chat) {
    // TODO: Replace with actual unread logic
    bool hasUnread = true; // For demo
    return hasUnread
        ? Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          )
        : SizedBox.shrink();
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  ChatDetailScreen({required this.chatId, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'profile_$otherUserId',
          child: CircleAvatar(child: Text(otherUserId.isNotEmpty ? otherUserId[0] : '?')),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: Center(child: Text('Chat with $otherUserId (chatId: $chatId)')),
    );
  }
}
