import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rx<User?> currentUser = Rx<User?>(null);
  var isInitialized = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }
  
  void _initializeAuth() async {
    try {
      // Set current user if already logged in
      currentUser.value = _auth.currentUser;
      
      // Listen to auth state changes
      currentUser.bindStream(_auth.authStateChanges());
      
      // Only navigate if we're not on splash screen and after a delay
      ever(currentUser, (User? user) {
        if (Get.currentRoute != '/splash') {
          Future.delayed(Duration(milliseconds: 1000), () {
            _setInitialScreen(user);
          });
        }
      });
      
      isInitialized.value = true;
      print('AuthService initialized successfully');
    } catch (e) {
      print('Error initializing AuthService: $e');
      isInitialized.value = true; // Set to true even on error to prevent hanging
    }
  }
  
  void _setInitialScreen(User? user) {
    if (!isInitialized.value) return;
    
    // Add a small delay to ensure the app is ready
    Future.delayed(Duration(milliseconds: 500), () {
      if (user == null) {
        // User is not logged in, redirect to welcome screen
        if (Get.currentRoute != '/') {
          Get.offAllNamed('/');
        }
      } else {
        // User is logged in, redirect to home screen
        if (Get.currentRoute != '/home') {
          Get.offAllNamed('/home');
        }
      }
    });
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  bool get isLoggedIn => _auth.currentUser != null;
  User? get user => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;
  String? get userPhone => _auth.currentUser?.phoneNumber;
}
