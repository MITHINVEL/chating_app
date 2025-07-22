import 'package:get/get.dart';
import '../views/welcome/welcome_screen.dart';
import '../views/login/login_screen.dart';
import '../views/register/register_screen.dart';
import '../views/forget_password/forget_password_screen.dart';
import '../views/otp/otp_screen.dart';
import '../views/splash/splash_screen.dart';
import '../views/home/home_screen.dart';
import '../views/group/group_screen.dart';
import '../views/call/call_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/search/user_search_screen.dart';
import '../views/chat/chat_screen.dart';
import '../views/chat/chat_list_screen.dart';
import '../../models/chat_user.dart';

class AppPages {
  static final routes = [
    GetPage(name: '/', page: () => WelcomeScreen()),
    GetPage(name: '/splash', page: () => SplashScreen()),
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/register', page: () => RegisterScreen()),
    GetPage(name: '/forget', page: () => ForgetPasswordScreen()),
    GetPage(name: '/otp', page: () => OTPScreen()),
    GetPage(name: '/home', page: () => HomeScreen()),
    GetPage(name: '/contacts', page: () => UserSearchScreen()),
    GetPage(name: '/chats', page: () => ChatListScreen()), // Added chat list
    GetPage(name: '/chat', page: () {
      final ChatUser otherUser = Get.arguments as ChatUser;
      return ChatScreen(otherUser: otherUser);
    }),
    GetPage(name: '/group', page: () => GroupScreen()),
    GetPage(name: '/call', page: () => CallScreen()),
    GetPage(name: '/settings', page: () => SettingsScreen()),
  ];
}
