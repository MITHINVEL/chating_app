import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/user_service.dart';
import '../../services/controller_service.dart';
import '../../../models/chat_user.dart';

class HomeController extends GetxController {
  final UserService userService = Get.find<UserService>();
  
  var currentUser = Rx<ChatUser?>(null);
  var showProfile = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }
  
  void loadUserData() async {
    try {
      final user = await userService.getCurrentUserData();
      if (user != null) {
        currentUser.value = user;
      } else {
        print('No user data found, user might need to re-login');
        // Don't logout automatically, just log the issue
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Handle error gracefully without crashing
    }
  }
  
  void toggleProfile() {
    showProfile.toggle();
  }
  
  void logout() {
    Get.defaultDialog(
      title: 'Logout',
      content: Text('Are you sure you want to logout?'),
      textCancel: 'Cancel',
      textConfirm: 'Logout',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        userService.updateOnlineStatus(false);
        Get.offAllNamed('/');
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, SafeControllerInit {
  late final HomeController controller;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  
  @override
  void initState() {
    super.initState();
    controller = getController<HomeController>(() => HomeController());
    
    animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));
    
    slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    ));
    
    animationController.forward();
  }
  
  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[400]!,
                    Colors.indigo[600]!,
                    Colors.blue[500]!,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                title: FadeTransition(
                  opacity: fadeAnimation,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'TM Chats',
                        textStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        speed: Duration(milliseconds: 150),
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
              ),
            ),
            actions: [
              Obx(() => Padding(
                padding: EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: controller.toggleProfile,
                  child: Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: controller.currentUser.value?.photoURL != null 
                            ? NetworkImage(controller.currentUser.value!.photoURL!) 
                            : null,
                        child: controller.currentUser.value?.photoURL == null 
                            ? Text(
                                controller.currentUser.value?.displayName.isNotEmpty == true
                                    ? controller.currentUser.value!.displayName[0].toUpperCase() 
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
                  ),
                ),
              )),
            ],
          ),
          
          // Profile Section (Expandable)
          Obx(() => controller.showProfile.value 
              ? SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: _buildProfileSection(),
                    ),
                  ),
                )
              : SliverToBoxAdapter(child: SizedBox.shrink())),
          
          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: _buildMainContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Header
          Row(
            children: [
              Hero(
                tag: 'profile_avatar_large',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple[300]!, Colors.indigo[400]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: controller.currentUser.value?.photoURL != null 
                          ? NetworkImage(controller.currentUser.value!.photoURL!) 
                          : null,
                      child: controller.currentUser.value?.photoURL == null 
                          ? Text(
                              controller.currentUser.value?.displayName.isNotEmpty == true
                                  ? controller.currentUser.value!.displayName[0].toUpperCase() 
                                  : '?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentUser.value?.displayName ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '@${controller.currentUser.value?.username ?? 'username'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (controller.currentUser.value?.bio != null && 
                        controller.currentUser.value!.bio!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        controller.currentUser.value!.bio!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.toggleProfile,
                icon: Icon(Icons.expand_less, color: Colors.grey[600]),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Profile Details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _buildProfileDetailRow(Icons.email, 'Email', 
                    controller.currentUser.value?.email ?? 'Not available'),
                SizedBox(height: 12),
                _buildProfileDetailRow(Icons.phone, 'Mobile', 
                    controller.currentUser.value?.mobile ?? 'Not provided'), // Added mobile display
                SizedBox(height: 12),
                _buildProfileDetailRow(Icons.calendar_today, 'Joined', 
                    _formatDate(controller.currentUser.value?.createdAt)),
                SizedBox(height: 12),
                _buildProfileDetailRow(Icons.circle, 'Status', 
                    controller.currentUser.value?.isOnline == true ? 'Online' : 'Offline',
                    statusColor: controller.currentUser.value?.isOnline == true ? Colors.green : Colors.grey),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  color: Colors.indigo,
                  onTap: () {
                    Get.snackbar('Coming Soon', 'Profile editing feature will be available soon!');
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.red,
                  onTap: controller.logout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.indigo, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor ?? Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[400]!, color[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange[100]!, Colors.pink[100]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.waving_hand, color: Colors.orange, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Ready to start chatting?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionCard(
                icon: Icons.message,
                title: 'Messages',
                subtitle: 'View all chats',
                color: Colors.blue,
                onTap: () => Get.toNamed('/chats'),
              ),
              _buildQuickActionCard(
                icon: Icons.search,
                title: 'Find People',
                subtitle: 'Search users to chat',
                color: Colors.green,
                onTap: () => Get.toNamed('/contacts'),
              ),
              _buildQuickActionCard(
                icon: Icons.group,
                title: 'Groups',
                subtitle: 'Join group chats',
                color: Colors.purple,
                onTap: () => Get.toNamed('/group'),
              ),
              _buildQuickActionCard(
                icon: Icons.call,
                title: 'Calls',
                subtitle: 'Voice & video calls',
                color: Colors.orange,
                onTap: () => Get.toNamed('/call'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color[50]!, color[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color[700], size: 24),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
