import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/user_service.dart';
import '../../services/controller_service.dart';
import '../../../models/chat_user.dart';

class UserSearchController extends GetxController {
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var searchResults = <ChatUser>[].obs;
  var recentChats = <ChatUser>[].obs;
  
  final UserService userService = Get.find<UserService>();
  
  // Search users by username or display name
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      searchResults.clear();
      return;
    }
    
    isLoading.value = true;
    
    try {
      // Search by both username and display name
      final usernameResults = await userService.searchUsersByUsername(query);
      final displayNameResults = await userService.searchUsersByDisplayName(query);
      
      // Combine and remove duplicates
      final allResults = <ChatUser>[];
      allResults.addAll(usernameResults);
      
      for (var user in displayNameResults) {
        if (!allResults.any((existingUser) => existingUser.uid == user.uid)) {
          allResults.add(user);
        }
      }
      
      searchResults.value = allResults;
    } catch (e) {
      Get.snackbar('Error', 'Failed to search users');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Start chat with user
  void startChatWith(ChatUser user) {
    // Navigate to chat screen with the selected user
    Get.toNamed('/chat', arguments: user);
  }
  
  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
  }
}

class UserSearchScreen extends StatefulWidget {
  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> 
    with TickerProviderStateMixin, SafeControllerInit {
  late final UserSearchController controller;
  final TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = getController<UserSearchController>(() => UserSearchController());
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Find People'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.indigo, Colors.indigo.shade300],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by username or name...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.indigo),
                    suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              controller.clearSearch();
                            },
                          )
                        : SizedBox.shrink(),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                    controller.searchUsers(value);
                  },
                ),
              ),
            ),
          ),
          
          // Search results
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return _buildWelcomeMessage();
                }
                
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.indigo),
                        SizedBox(height: 16),
                        Text(
                          'Searching...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (controller.searchResults.isEmpty) {
                  return _buildNoResults();
                }
                
                return _buildSearchResults();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Find People to Chat',
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
              'Search for people by their username or display name to start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Try searching with a different username or name',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(ChatUser user) {
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
        leading: Hero(
          tag: 'avatar_${user.uid}',
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.indigo.shade100,
            backgroundImage: user.photoURL != null 
                ? NetworkImage(user.photoURL!) 
                : null,
            child: user.photoURL == null 
                ? Text(
                    user.displayName.isNotEmpty 
                        ? user.displayName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                user.bio!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  user.isOnline 
                      ? 'Online' 
                      : 'Last seen ${_formatLastSeen(user.lastSeen)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.startChatWith(user),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
