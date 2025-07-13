import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String emailError = '';
  String passwordError = '';
  String phoneError = '';
  String otpError = '';
  bool isEmail = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String countryCode = '+91';
  bool showOtpField = false;
  String verificationId = '';
  bool passwordVisible = false;

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
                borderSide: BorderSide(color: emailError.isNotEmpty ? Colors.red : Colors.grey),
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
                      borderSide: BorderSide(color: phoneError.isNotEmpty ? Colors.red : Colors.grey),
                    ),
                    errorText: phoneError.isNotEmpty ? phoneError : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              setState(() { phoneError = ''; });
              if (phoneController.text.isEmpty) {
                setState(() { phoneError = 'Enter phone number'; });
                return;
              }
              // Request SMS and notification permissions
              bool smsGranted = true;
              bool notifGranted = true;
              try {
                // Request SMS permission
                final smsStatus = await [Permission.sms].request();
                smsGranted = smsStatus[Permission.sms]?.isGranted ?? true;
                // Request notification permission
                final notifStatus = await [Permission.notification].request();
                notifGranted = notifStatus[Permission.notification]?.isGranted ?? true;
              } catch (e) {
                smsGranted = true; notifGranted = true; // fallback for web/unsupported
              }
              if (!smsGranted) {
                setState(() { phoneError = 'SMS permission denied. Please enable SMS permission.'; });
                return;
              }
              if (!notifGranted) {
                setState(() { phoneError = 'Notification permission denied. Please enable notification permission.'; });
                return;
              }
              // Check Firestore for registered phone number
              final phoneDoc = await FirebaseFirestore.instance.collection('users')
                .where('phone', isEqualTo: countryCode + phoneController.text)
                .limit(1)
                .get();
              if (phoneDoc.docs.isEmpty) {
                setState(() { phoneError = "Don't have this number"; });
                return;
              }
              // Show OTP input and start timer immediately
              setState(() {
                showOtpField = true;
                otpError = '';
              });
              startOtpTimer();
              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: countryCode + phoneController.text,
                verificationCompleted: (PhoneAuthCredential credential) async {
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  // TODO: Navigate to home or next screen
                },
                verificationFailed: (FirebaseAuthException e) {
                  setState(() { phoneError = e.message ?? 'Phone verification failed'; });
                },
                codeSent: (String verId, int? resendToken) {
                  setState(() {
                    verificationId = verId;
                  });
                },
                codeAutoRetrievalTimeout: (String verId) {
                  verificationId = verId;
                },
              );
            },
            child: Text('Send OTP'),
          ),
          if (showOtpField) ...[
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: i == 0 && otpError.isNotEmpty ? Colors.red : Colors.grey,
                              ),
                            ),
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
        ],
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              emailError = '';
              passwordError = '';
              phoneError = '';
              otpError = '';
            });
            if (isEmail) {
              bool hasError = false;
              if (emailController.text.isEmpty) {
                setState(() { emailError = 'Enter email'; });
                hasError = true;
              }
              if (passwordController.text.isEmpty) {
                setState(() { passwordError = 'Enter password'; });
                hasError = true;
              }
              if (hasError) return;
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );
                // Navigate to home screen after successful login
                Get.offAllNamed('/home');
              } catch (e) {
                if (e is FirebaseAuthException) {
                  if (e.code == 'user-not-found') {
                    setState(() { emailError = 'Incorrect email'; });
                  } else if (e.code == 'wrong-password') {
                    setState(() { passwordError = 'Incorrect password'; });
                  } else {
                    setState(() { emailError = e.message ?? 'Login failed'; });
                  }
                } else {
                  setState(() { emailError = 'Login failed'; });
                }
              }
            } else {
              if (!showOtpField) {
                if (phoneController.text.isEmpty) {
                  setState(() { phoneError = 'Enter phone number'; });
                  return;
                }
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: countryCode + phoneController.text,
                  verificationCompleted: (PhoneAuthCredential credential) async {
                    await FirebaseAuth.instance.signInWithCredential(credential);
                    // TODO: Navigate to home or next screen
                  },
                  verificationFailed: (FirebaseAuthException e) {
                    setState(() { phoneError = e.message ?? 'Phone verification failed'; });
                  },
                  codeSent: (String verId, int? resendToken) {
                    setState(() {
                      verificationId = verId;
                      showOtpField = true;
                    });
                  },
                  codeAutoRetrievalTimeout: (String verId) {
                    verificationId = verId;
                  },
                );
              } else {
                String otpValue = otpControllers.map((c) => c.text).join();
                if (otpValue.length < 6) {
                  setState(() { otpError = 'Enter OTP'; });
                  return;
                }
                if (otpExpired) {
                  setState(() { otpError = 'OTP expired. Please resend.'; });
                  return;
                }
                try {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: otpValue,
                  );
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  // Store phone number in Firestore after successful login
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'phone': countryCode + phoneController.text,
                      'uid': user.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  }
                  // Navigate to home screen after successful login
                  Get.offAllNamed('/home');
                } catch (e) {
                  setState(() { otpError = 'Invalid OTP or login failed'; });
                }
              }
            }
          },
          child: Text(showOtpField ? 'Verify OTP' : 'Sign In'),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Get.toNamed('/forget'),
          child: Text('Forgot Password?'),
        ),
        Row(
          children: [
            SizedBox(width: 10),
            Text('Don\'t have an account?',
                style: TextStyle(fontSize: 20)),
            TextButton(
              onPressed: () => Get.toNamed('/register'),
              child: Text('Register', style: TextStyle(fontSize: 18),
            ),
            )
          ],
        ),
      ],
    );
  }
}
