import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          SvgPicture.asset('assets/images/login.svg', height: 150),
          SizedBox(height: 20),
          Text('Sign In', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {}, // Email sign in logic
            child: Text('Sign in with Email'),
          ),
          ElevatedButton(
            onPressed: () {}, // Phone sign in logic
            child: Text('Sign in with Phone'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          TextButton(
            onPressed: () => Get.toNamed('/forget'),
            child: Text('Forgot Password?'),
          ),
        ],
      ),
    );
  }
}
