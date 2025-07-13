import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool isEmail = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

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
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
        ] else ...[
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (isEmail) {
              // TODO: Implement Firebase email/password sign in
              // Example:
              // await FirebaseAuth.instance.signInWithEmailAndPassword(
              //   email: emailController.text,
              //   password: passwordController.text,
              // );
            } else {
              // TODO: Implement Firebase phone sign in
              // Example:
              // await FirebaseAuth.instance.verifyPhoneNumber(
              //   phoneNumber: phoneController.text,
              //   ...
              // );
            }
          },
          child: Text('Sign In'),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Get.toNamed('/forget'),
          child: Text('Forgot Password?'),
        ),
        TextButton(
          onPressed: () => Get.toNamed('/register'),
          child: Text('Register'),
        ),
      ],
    );
  }
}
