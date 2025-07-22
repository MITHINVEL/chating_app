import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/controller_service.dart';
import '../../services/user_service.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  var selectedCountry = 'India'.obs;
  var selectedCountryCode = '+91'.obs;
  var phoneNumber = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var isPhoneMode = false.obs; // false for email (default), true for phone
  
  String? verificationId;
  final UserService _userService = Get.find<UserService>();
  
  // Toggle between phone and email login modes
  void toggleLoginMode() {
    isPhoneMode.value = !isPhoneMode.value;
  }
  
  // Email/Password login with enhanced validation
  Future<void> signInWithEmail(String email, String password) async {
    isLoading.value = true;
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Check if user exists in our Firestore database
        final userData = await _userService.getCurrentUserData();
        
        if (userData != null) {
          // User exists in our database
          isLoading.value = false;
          Get.offAllNamed('/home');
          Get.snackbar(
            '🎉 Welcome Back!',
            'Hello ${userData.displayName}! Ready to chat?',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
            icon: Icon(Icons.check_circle, color: Colors.white),
          );
        } else {
          // User authenticated but not in our database
          await FirebaseAuth.instance.signOut();
          isLoading.value = false;
          Get.snackbar(
            '❌ Not Registered',
            'You are not registered in our chat system. Please register first to start chatting!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade600,
            colorText: Colors.white,
            duration: Duration(seconds: 4),
            icon: Icon(Icons.warning_rounded, color: Colors.white),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage = '';
      Color backgroundColor = Colors.red.shade600;
      IconData iconData = Icons.error;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '❌ You are not registered. Please create an account first to join our chat community!';
          backgroundColor = Colors.orange.shade600;
          iconData = Icons.person_add;
          break;
        case 'wrong-password':
          errorMessage = '🔒 Incorrect password. Please check and try again.';
          iconData = Icons.lock;
          break;
        case 'invalid-email':
          errorMessage = '📧 Please enter a valid email address.';
          iconData = Icons.email;
          break;
        case 'user-disabled':
          errorMessage = '🚫 Your account has been disabled. Contact support.';
          iconData = Icons.block;
          break;
        case 'too-many-requests':
          errorMessage = '⏰ Too many login attempts. Please try again later.';
          iconData = Icons.access_time;
          break;
        default:
          errorMessage = '❌ ${e.message ?? 'Login failed. Please try again.'}';
      }
      
      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
        icon: Icon(iconData, color: Colors.white),
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Connection Error',
        '❌ Network error occurred. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.wifi_off, color: Colors.white),
      );
    }
  }
  
  // Phone OTP login (existing method)
  Future<void> sendOTP(BuildContext context, String phoneNumber) async {
    isLoading.value = true;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '$selectedCountryCode$phoneNumber',
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          Get.snackbar(
            'Error',
            e.message ?? 'Verification failed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId = verificationId;
          isLoading.value = false;
          Get.toNamed('/otp', arguments: {
            'verificationId': verificationId,
            'phoneNumber': '$selectedCountryCode$phoneNumber',
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to send OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin, SafeControllerInit {
  late final LoginController controller;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize GetX controller safely
    controller = getController<LoginController>(() => LoginController());
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_buttonAnimationController);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.pink.shade300,
              Colors.orange.shade300,
              Colors.yellow.shade200,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Back button with enhanced styling
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                SizedBox(height: 40),
                
                // Welcome animation with enhanced styling
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  controller.isPhoneMode.value ? 'Phone Login 📱' : 'Welcome Back! 🎉',
                                  textStyle: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                  speed: Duration(milliseconds: 100),
                                ),
                              ],
                              isRepeatingAnimation: false,
                              key: ValueKey(controller.isPhoneMode.value),
                            )),
                            SizedBox(height: 8),
                            Obx(() => Text(
                              controller.isPhoneMode.value 
                                  ? 'Enter your phone number to continue 📞'
                                  : 'Enter your email and password to chat 💬',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 60),
                
                // SVG illustration with enhanced container
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/login.svg',
                        height: 180,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 60),
                
                // Dynamic input section (Phone or Email)
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Obx(() => controller.isPhoneMode.value 
                            ? _buildPhoneInput() 
                            : _buildEmailInput()),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 20),
                
                // Login mode toggle with updated styling
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.isPhoneMode.value 
                                  ? 'Prefer email login? ' 
                                  : 'Prefer phone login? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.toggleLoginMode(),
                              child: Text(
                                controller.isPhoneMode.value 
                                    ? 'Use Email 📧' 
                                    : 'Use Phone 📱',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 40),
                
                // Enhanced Login button
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Obx(() => GestureDetector(
                          onTapDown: (_) => _buttonAnimationController.forward(),
                          onTapUp: (_) => _buttonAnimationController.reverse(),
                          onTapCancel: () => _buttonAnimationController.reverse(),
                          onTap: () => _handleLogin(),
                          child: ScaleTransition(
                            scale: _buttonScaleAnimation,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: controller.isLoading.value
                                  ? Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      controller.isPhoneMode.value ? 'Send OTP 📱' : 'Login 🚀',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.purple.shade700,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        )),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 30),
                
                // Register option with updated styling
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.toNamed('/register'),
                              child: Text(
                                'Register 📝',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to handle login based on mode
  void _handleLogin() {
    if (controller.isLoading.value) return;
    
    if (controller.isPhoneMode.value) {
      if (phoneController.text.isNotEmpty) {
        controller.sendOTP(context, phoneController.text);
      }
    } else {
      if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
        controller.signInWithEmail(emailController.text, passwordController.text);
      }
    }
  }

  // Helper method to build phone input with enhanced styling
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number 📱',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country picker with enhanced styling
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (Country country) {
                      controller.selectedCountry.value = country.countryCode;
                      controller.selectedCountryCode.value = '+${country.phoneCode}';
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.selectedCountryCode.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Colors.purple.shade600),
                    ],
                  )),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.purple.shade200,
              ),
              // Phone number input
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  onChanged: (value) {
                    controller.phoneNumber.value = value;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build email input with enhanced styling
  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address 📧',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.purple.shade600),
            ),
            onChanged: (value) {
              controller.email.value = value;
            },
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Password 🔒',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              prefixIcon: Icon(Icons.lock_outlined, color: Colors.purple.shade600),
            ),
            onChanged: (value) {
              controller.password.value = value;
            },
          ),
        ),
      ],
    );
  }
}
