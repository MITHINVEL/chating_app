import 'package:get/get.dart';
import '../views/welcome/welcome_screen.dart';
import '../views/login/login_screen.dart';
import '../views/register/register_screen.dart';
import '../views/forget_password/forget_password_screen.dart';
import '../views/home/home_screen.dart';
import '../views/chat/chat_screen.dart';
import '../views/group/group_screen.dart';
import '../views/call/call_screen.dart';
import '../views/settings/settings_screen.dart';

class AppPages {
  static final routes = [
    GetPage(name: '/', page: () => WelcomeScreen()),
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/register', page: () => RegisterScreen()),
    GetPage(name: '/forget', page: () => ForgetPasswordScreen()),
    GetPage(name: '/home', page: () => HomeScreen()),
    GetPage(name: '/chat', page: () => ChatScreen()),
    GetPage(name: '/group', page: () => GroupScreen()),
    GetPage(name: '/call', page: () => CallScreen()),
    GetPage(name: '/settings', page: () => SettingsScreen()),
  ];
}
