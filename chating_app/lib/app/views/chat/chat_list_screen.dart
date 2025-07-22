import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/controller_service.dart';
import '../../services/user_service.dart';
import '../../../models/chat_user.dart';
import '../../../models/chat_list_item.dart';

class ChatListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService userService = Get.find<UserService>();
  
  var chatList = <ChatListItem>[].obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadChatList();
  }
  
  // Load chat list from Firestore
  void loadChatList() {
    if (_auth.currentUser == null) return;
    
    _firestore
        .collection('chats')
        .where('participants', arrayContains: _auth.currentUser!.uid)
        .snapshots()
        .listen((snapshot) async {
      
      final List<ChatListItem> chats = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        // Find the other user ID
        final otherUserId = participants.firstWhere(
          (id) => id != _auth.currentUser!.uid,
          orElse: () => '',
        );
        
        if (otherUserId.isNotEmpty) {
          // Get other user data
          final otherUser = await userService.getUserByUid(otherUserId);
          
          if (otherUser != null) {
            // Count unread messages
            final unreadCount = await _getUnreadCount(doc.id);
            
            final chatItem = ChatListItem(
              chatId: doc.id,
              otherUser: otherUser,
              lastMessage: data['lastMessage'] ?? '',
              lastMessageTime: DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'] ?? 0),
              lastMessageSender: data['lastMessageSender'] ?? '',
              unreadCount: unreadCount,
            );
            
            chats.add(chatItem);
          }
        }
      }
      
      // Sort chats by last message time (most recent first)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      chatList.value = chats;
      isLoading.value = false;
    });
  }
  
  // Get unread message count for a chat
  Future<int> _getUnreadCount(String chatId) async {
    if (_auth.currentUser == null) return 0;
    
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      return unreadMessages.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
  // Navigate to chat screen
  void openChat(ChatUser otherUser) {
    Get.toNamed('/chat', arguments: otherUser);
  }
  
  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
      Get.snackbar('Success', 'Chat deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete chat');
    }
  }
  
  // Filter chats based on search query
  List<ChatListItem> get filteredChats {
    if (searchQuery.value.isEmpty) return chatList;
    
    return chatList.where((chat) {
      return chat.otherUser.displayName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          chat.otherUser.username
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());
    }).toList();
  }
}

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> 
    with TickerProviderStateMixin, SafeControllerInit {
  late final ChatListController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    controller = getController<ChatListController>(() => ChatListController());
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Get.toNamed('/contacts'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              controller.searchQuery.value = '';
                            },
                          )
                        : SizedBox.shrink(),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                  },
                ),
              ),
            ),
          ),
          
          // Chat List
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.indigo),
                        SizedBox(height: 16),
                        Text(
                          'Loading chats...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final chats = controller.filteredChats;
                
                if (chats.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatItem(chat);
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/contacts'),
        backgroundColor: Colors.indigo,
        child: Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Colors.indigo[300],
            ),
          ),
          SizedBox(height: 20),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'No Chats Yet',
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                speed: Duration(milliseconds: 100),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start a conversation by finding people to chat with',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/contacts'),
            icon: Icon(Icons.search),
            label: Text('Find People'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatListItem chat) {
    final isMe = chat.lastMessageSender == FirebaseAuth.instance.currentUser?.uid;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Stack(
          children: [
            Hero(
              tag: 'chat_avatar_${chat.otherUser.uid}',
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.indigo[100],
                backgroundImage: chat.otherUser.photoURL != null 
                    ? NetworkImage(chat.otherUser.photoURL!) 
                    : null,
                child: chat.otherUser.photoURL == null 
                    ? Text(
                        chat.otherUser.displayName.isNotEmpty 
                            ? chat.otherUser.displayName[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      )
                    : null,
              ),
            ),
            if (chat.otherUser.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.otherUser.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Text(
              _formatTime(chat.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (isMe) ...[
              Icon(
                Icons.done_all,
                size: 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                chat.lastMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => controller.openChat(chat.otherUser),
        onLongPress: () => _showChatOptions(chat),
      ),
    );
  }

  void _showChatOptions(ChatListItem chat) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.chat, color: Colors.indigo),
              title: Text('Open Chat'),
              onTap: () {
                Get.back();
                controller.openChat(chat.otherUser);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('View Profile'),
              onTap: () {
                Get.back();
                // TODO: Show user profile
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete Chat'),
              onTap: () {
                Get.back();
                _showDeleteConfirmation(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ChatListItem chat) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat with ${chat.otherUser.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteChat(chat.chatId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      }
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
