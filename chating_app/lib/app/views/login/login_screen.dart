import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Helper: Generate random 6-digit OTP
String generateOtp() {
  final random = DateTime.now().millisecondsSinceEpoch % 1000000;
  return random.toString().padLeft(6, '0');
}

// Helper: Send SMS using a placeholder API (replace with your SMS provider)
Future<void> sendSms(BuildContext context, String phone, String otp) async {
  // Use Firebase Auth to send OTP SMS
  await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: phone,
    timeout: Duration(seconds: 60),
    verificationCompleted: (PhoneAuthCredential credential) {
      // Auto-retrieval or instant verification
    },
    verificationFailed: (FirebaseAuthException e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Verification Failed'),
          content: Text(e.message ?? 'Unknown error'),
        ),
      );
    },
    codeSent: (String verificationId, int? resendToken) {
      // Store verificationId for later OTP verification
      // You may want to save this in your state
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('OTP Sent'),
          content: Text('OTP has been sent to your phone.'),
        ),
      );
    },
    codeAutoRetrievalTimeout: (String verificationId) {},
  );
}

Future<void> storeOtp(String phone, String otp) async {
  await FirebaseFirestore.instance.collection('otp').doc(phone).set({
    'otp': otp,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresIn': 120, // seconds
  });
}

// Verify OTP from Firestore
Future<bool> verifyOtp(String phone, String enteredOtp) async {
  final doc = await FirebaseFirestore.instance.collection('otp').doc(phone).get();
  if (!doc.exists) return false;
  final data = doc.data();
  if (data == null) return false;
  final otp = data['otp'] as String?;
  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
  final expiresIn = data['expiresIn'] as int? ?? 120;
  if (otp == null || createdAt == null) return false;
  final now = DateTime.now();
  if (now.difference(createdAt).inSeconds > expiresIn) return false;
  return enteredOtp == otp;
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final TextEditingController phoneController = TextEditingController();
  bool isEmail = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String emailError = '';
  String passwordError = '';
  String phoneError = '';
  String otpError = '';
  String countryCode = '+91';
  bool passwordVisible = false;
  bool showOtpField = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    await Permission.sms.request();
  }

  final List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());
  int otpSeconds = 0;
  bool otpExpired = false;

  void startOtpTimer() {
    otpSeconds = 25;
    otpExpired = false;
    setState(() {});
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (otpSeconds > 0) {
        otpSeconds--;
        setState(() {});
        return true;
      } else {
        otpExpired = true;
        setState(() {});
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        SizedBox(height: 50),
        SvgPicture.asset('assets/images/login.svg', height: 200),
        SizedBox(height: 40),
        Text('Sign In', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: Text('Email'),
              selected: isEmail,
              onSelected: (selected) {
                setState(() {
                  isEmail = true;
                });
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(color: isEmail ? Colors.white : Colors.black),
            ),
            SizedBox(width: 12),
            ChoiceChip(
              label: Text('Phone'),
              selected: !isEmail,
              onSelected: (selected) {
                setState(() {
                  isEmail = false;
                });
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(color: !isEmail ? Colors.white : Colors.black),
            ),
          ],
        ),
        SizedBox(height: 24),
        if (isEmail) ...[
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: emailError.isNotEmpty ? emailError : null,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              errorText: passwordError.isNotEmpty ? passwordError : null,
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    passwordVisible = !passwordVisible;
                  });
                },
              ),
            ),
            obscureText: !passwordVisible,
          ),
        ] else ...[
          Row(
            children: [
              InkWell(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (country) {
                      setState(() {
                        countryCode = '+${country.phoneCode}';
                      });
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(countryCode, style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: phoneError.isNotEmpty ? phoneError : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              setState(() { phoneError = ''; otpError = ''; });
              final phone = countryCode + phoneController.text;
              if (phoneController.text.isEmpty) {
                setState(() { phoneError = 'Enter phone number'; });
                return;
              }
              // Check Firestore for registered phone number
              final phoneDoc = await FirebaseFirestore.instance.collection('users')
                .where('phone', isEqualTo: phone)
                .limit(1)
                .get();
              if (phoneDoc.docs.isEmpty) {
                setState(() { phoneError = "Don't register this number"; });
                return;
              }
              // Generate OTP, store, and send SMS
              final otp = generateOtp();
              await storeOtp(phone, otp);
              // final now = DateTime.now();
              // final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              await sendSms(context, phone, otp);
              setState(() {
                showOtpField = true;
                otpError = '';
              });
              startOtpTimer();
            },
            child: Text('Send OTP'),
          ),
          if (showOtpField)
            Column(
              children: [
                SizedBox(height: 16),
                Text('Enter 6 digit OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 6; i++)
                      Container(
                        width: 32,
                        height: 40,
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        child: TextField(
                          controller: otpControllers[i],
                          focusNode: otpFocusNodes[i],
                          enabled: !otpExpired,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            if (value.length == 1 && i < 5) {
                              FocusScope.of(context).requestFocus(otpFocusNodes[i + 1]);
                            }
                            if (value.isEmpty && i > 0) {
                              FocusScope.of(context).requestFocus(otpFocusNodes[i - 1]);
                            }
                          },
                        ),
                      ),
                    SizedBox(width: 10),
                    Text(
                      otpExpired ? 'Expired' : '${otpSeconds}s',
                      style: TextStyle(
                        color: otpExpired ? Colors.red : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (otpError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      otpError,
                      style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
        ],
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              emailError = '';
              passwordError = '';
            });
            if (isEmail) {
              // Email/password login with Firebase
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (email.isEmpty) {
                setState(() { emailError = 'Enter email'; });
                return;
              }
              if (password.isEmpty) {
                setState(() { passwordError = 'Enter password'; });
                return;
              }
              try {
                final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                // Login success: update Firestore user last login
                final userId = userCredential.user?.uid;
                if (userId != null) {
                  await FirebaseFirestore.instance.collection('users').doc(userId).set({
                    'lastLogin': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                }
                // Navigate to home screen
                Get.offAllNamed('/home');
              } catch (e) {
                setState(() { emailError = 'Invalid email or password'; });
              }
            } else {
              final phone = countryCode + phoneController.text;
              if (!showOtpField) {
                setState(() { phoneError = 'Please send OTP first'; });
                return;
              }
              String otpValue = otpControllers.map((c) => c.text).join();
              if (otpValue.length < 6) {
                setState(() { otpError = 'Enter OTP'; });
                return;
              }
              if (otpExpired) {
                setState(() { otpError = 'OTP expired. Please resend.'; });
                return;
              }
              bool valid = await verifyOtp(phone, otpValue);
              if (valid) {
                // Login success: update Firestore user last login
                final phoneDoc = await FirebaseFirestore.instance.collection('users')
                  .where('phone', isEqualTo: phone)
                  .limit(1)
                  .get();
                if (phoneDoc.docs.isNotEmpty) {
                  final userId = phoneDoc.docs.first.id;
                  await FirebaseFirestore.instance.collection('users').doc(userId).set({
                    'lastLogin': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                }
                // Navigate to home screen
                Get.offAllNamed('/home');
              }
            }
          },
          child: Text('Sign In'),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Get.toNamed('/forget'),
          child: Text('Forgot Password?'),
        ),
        Row(
          children: [
            SizedBox(width: 10),
            Text("Don't have an account?", style: TextStyle(fontSize: 20)),
            TextButton(
              onPressed: () => Get.toNamed('/register'),
              child: Text('Register', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ],
    );
  }
            }
