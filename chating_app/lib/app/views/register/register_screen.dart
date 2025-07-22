import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/user_service.dart';
import '../../services/controller_service.dart';

class RegisterController extends GetxController {
  var isLoading = false.obs;
  var isCheckingUsername = false.obs;
  var isUsernameAvailable = false.obs;
  var username = ''.obs;
  var displayName = ''.obs;
  var email = ''.obs;
  var mobile = ''.obs; // Added mobile field
  var password = ''.obs;
  var confirmPassword = ''.obs;
  var bio = ''.obs;
  
  final UserService userService = Get.find<UserService>();
  
  // Check username availability as user types
  Future<void> checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      isUsernameAvailable.value = false;
      return;
    }
    
    isCheckingUsername.value = true;
    isUsernameAvailable.value = await userService.isUsernameAvailable(username);
    isCheckingUsername.value = false;
  }
  
  // Register new user
  Future<void> registerUser() async {
    if (isLoading.value) return;
    
    if (!_validateInputs()) return;
    
    isLoading.value = true;
    
    bool success = await userService.createUserWithUsername(
      email: email.value,
      password: password.value,
      username: username.value,
      displayName: displayName.value,
      mobile: mobile.value.isEmpty ? null : mobile.value, // Added mobile parameter
      bio: bio.value.isEmpty ? null : bio.value,
    );
    
    isLoading.value = false;
    
    if (success) {
      Get.offAllNamed('/home');
    }
  }
  
  bool _validateInputs() {
    if (username.value.length < 3) {
      Get.snackbar('Error', 'Username must be at least 3 characters');
      return false;
    }
    
    if (!isUsernameAvailable.value) {
      Get.snackbar('Error', 'Username is not available');
      return false;
    }
    
    if (displayName.value.length < 2) {
      Get.snackbar('Error', 'Display name must be at least 2 characters');
      return false;
    }
    
    if (!GetUtils.isEmail(email.value)) {
      Get.snackbar('Error', 'Please enter a valid email');
      return false;
    }
    
    if (password.value.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return false;
    }
    
    if (password.value != confirmPassword.value) {
      Get.snackbar('Error', 'Passwords do not match');
      return false;
    }
    
    return true;
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> 
    with TickerProviderStateMixin, SafeControllerInit {
  late final RegisterController controller;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize UserService if not already done
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    
    controller = getController<RegisterController>(() => RegisterController());
    
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
    usernameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // Back button
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 40),
              
              // Welcome animation
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
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Create Account',
                                textStyle: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                speed: Duration(milliseconds: 100),
                              ),
                            ],
                            isRepeatingAnimation: false,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your unique username and start chatting',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 40),
              
              // SVG illustration
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/register.svg',
                    height: 180,
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Input fields
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildUsernameField(),
                          SizedBox(height: 16),
                          _buildDisplayNameField(),
                          SizedBox(height: 16),
                          _buildEmailField(),
                          SizedBox(height: 16),
                          _buildMobileField(), // Added mobile field
                          SizedBox(height: 16),
                          _buildPasswordField(),
                          SizedBox(height: 16),
                          _buildConfirmPasswordField(),
                          SizedBox(height: 16),
                          _buildBioField(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40),
              
              // Register button
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
                        onTap: () => controller.registerUser(),
                        child: ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.3),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
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
              
              // Login option
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
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }

  // Helper method to build username field
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: usernameController,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Choose a unique username',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.alternate_email, color: Colors.grey[600]),
              suffixIcon: Obx(() {
                if (controller.isCheckingUsername.value) {
                  return Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (controller.username.value.length >= 3) {
                  return Icon(
                    controller.isUsernameAvailable.value 
                        ? Icons.check_circle 
                        : Icons.error,
                    color: controller.isUsernameAvailable.value 
                        ? Colors.green 
                        : Colors.red,
                  );
                }
                return SizedBox.shrink();
              }),
            ),
            onChanged: (value) {
              controller.username.value = value;
              if (value.length >= 3) {
                controller.checkUsernameAvailability(value);
              }
            },
          ),
        ),
        SizedBox(height: 4),
        Obx(() => controller.username.value.length >= 3 && !controller.isCheckingUsername.value
            ? Text(
                controller.isUsernameAvailable.value 
                    ? 'Username is available!' 
                    : 'Username is taken',
                style: TextStyle(
                  fontSize: 12,
                  color: controller.isUsernameAvailable.value 
                      ? Colors.green 
                      : Colors.red,
                ),
              )
            : SizedBox.shrink(),
        ),
      ],
    );
  }

  // Helper method to build display name field
  Widget _buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: displayNameController,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Your display name',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.displayName.value = value;
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build email field
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.email.value = value;
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build mobile field
  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile Number (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter your mobile number',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.mobile.value = value;
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build password field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Create a password',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.password.value = value;
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build confirm password field
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: confirmPasswordController,
            obscureText: true,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.confirmPassword.value = value;
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build bio field
  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: bioController,
            maxLines: 2,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Tell people about yourself...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
            ),
            onChanged: (value) {
              controller.bio.value = value;
            },
          ),
        ),
      ],
    );
  }
}