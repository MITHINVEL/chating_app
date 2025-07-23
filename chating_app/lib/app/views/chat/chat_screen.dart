import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/controller_service.dart';
import '../../../models/chat_user.dart';
import '../../../models/message.dart';
import '../../../views/call_screen.dart';

class ChatController extends GetxController {
  final ChatUser otherUser;
  
  ChatController({required this.otherUser});
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var isTyping = false.obs;
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  String get chatId {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final otherUserId = otherUser.uid;
    
    // Create a consistent chat ID by sorting user IDs
    return currentUserId.compareTo(otherUserId) < 0 
        ? '${currentUserId}_${otherUserId}'
        : '${otherUserId}_${currentUserId}';
  }
  
  @override
  void onInit() {
    super.onInit();
    loadMessages();
    markMessagesAsRead();
    
    // Mark messages as read whenever new messages arrive
    ever(messages, (_) {
      markMessagesAsRead();
    });
  }
  
  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
  
  // Load messages from Firestore
  void loadMessages() {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
      
      // Scroll to bottom when new message arrives
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Send message
  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty || _auth.currentUser == null) return;
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _auth.currentUser!.uid,
      receiverId: otherUser.uid,
      message: messageText,
      timestamp: DateTime.now(),
      isRead: false,
      messageType: MessageType.text,
    );
    
    // Clear the text field immediately
    messageController.clear();
    
    try {
      // Add message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
      
      // Update last message in chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [_auth.currentUser!.uid, otherUser.uid],
        'lastMessage': messageText,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageSender': _auth.currentUser!.uid,
      }, SetOptions(merge: true));
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead() async {
    if (_auth.currentUser == null) return;
    
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Batch update for better performance
      final batch = _firestore.batch();
      
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        print('Marked ${unreadMessages.docs.length} messages as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}

class ChatScreen extends StatefulWidget {
  final ChatUser otherUser;
  
  const ChatScreen({Key? key, required this.otherUser}) : super(key: key);
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with TickerProviderStateMixin, SafeControllerInit, WidgetsBindingObserver {
  late final ChatController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    controller = getController<ChatController>(
      () => ChatController(otherUser: widget.otherUser)
    );
    
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
    
    // Mark messages as read when screen opens
    Future.delayed(Duration(milliseconds: 500), () {
      controller.markMessagesAsRead();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Mark messages as read when app becomes active
    if (state == AppLifecycleState.resumed) {
      controller.markMessagesAsRead();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _handlePermissions(bool isVideo) async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      Get.snackbar('Permission Error', 'Microphone permission is required for calls');
      return false;
    }

    if (isVideo) {
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        Get.snackbar('Permission Error', 'Camera permission is required for video calls');
        return false;
      }
    }

    return true;
  }

  void _startCall(bool isVideo) async {
    final hasPermissions = await _handlePermissions(isVideo);
    if (!hasPermissions) return;

    final callID = "${controller.chatId}_${DateTime.now().millisecondsSinceEpoch}";
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) return;

    Get.to(() => CallScreen(
      callID: callID,
      userID: currentUser.uid,
      userName: currentUser.displayName ?? currentUser.uid,
      isVideo: isVideo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'chat_avatar_${widget.otherUser.uid}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo[100],
                backgroundImage: widget.otherUser.photoURL != null 
                    ? NetworkImage(widget.otherUser.photoURL!) 
                    : null,
                child: widget.otherUser.photoURL == null 
                    ? Text(
                        widget.otherUser.displayName.isNotEmpty 
                            ? widget.otherUser.displayName[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    widget.otherUser.isOnline ? 'Online' : 'Last seen recently',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.black),
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.black),
            onPressed: () => _startCall(true),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  controller: controller.scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                    
                    return _buildMessageBubble(message, isMe, index);
                  },
                );
              }),
            ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
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
                'Start Conversation',
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                speed: Duration(milliseconds: 100),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          SizedBox(height: 10),
          Text(
            'Send a message to start chatting with ${widget.otherUser.displayName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo[100],
              backgroundImage: widget.otherUser.photoURL != null 
                  ? NetworkImage(widget.otherUser.photoURL!) 
                  : null,
              child: widget.otherUser.photoURL == null 
                  ? Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8),
          ],
          // For sent messages, add left padding to push them more to the right
          if (isMe) SizedBox(width: 60),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe 
                    ? LinearGradient(
                        colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                      )
                    : LinearGradient(
                        colors: [Colors.grey[100]!, Colors.grey[200]!],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          child: Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.isRead ? Colors.lightBlue[300] : Colors.white70,
                          ),
                        ),
                        if (message.isRead) ...[
                          SizedBox(width: 2),
                          Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.lightBlue[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Add right padding for received messages to balance the layout
          if (!isMe) SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: controller.messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[400]!, Colors.indigo[600]!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: controller.sendMessage,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
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
              leading: Icon(Icons.person, color: Colors.indigo),
              title: Text('View Profile'),
              onTap: () {
                Get.back();
                _showUserProfile();
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text('Block User'),
              onTap: () {
                Get.back();
                _showBlockConfirmation();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Clear Chat'),
              onTap: () {
                Get.back();
                _showClearChatConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.indigo[100],
                backgroundImage: widget.otherUser.photoURL != null 
                    ? NetworkImage(widget.otherUser.photoURL!) 
                    : null,
                child: widget.otherUser.photoURL == null 
                    ? Text(
                        widget.otherUser.displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: 16),
              Text(
                widget.otherUser.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${widget.otherUser.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.indigo,
                ),
              ),
              if (widget.otherUser.bio != null && widget.otherUser.bio!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  widget.otherUser.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block ${widget.otherUser.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Blocked', 'User has been blocked');
            },
            child: Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('Clear Chat'),
        content: Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Cleared', 'Chat has been cleared');
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
