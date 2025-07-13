import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          SvgPicture.asset('assets/images/register.svg', height: 150),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(labelText: 'Full Name'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Mobile Number (with country code)'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Email Address'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Confirm Password'),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {}, // Register logic
            child: Text('Create Account'),
          ),
          TextButton(
            onPressed: () => Get.toNamed('/login'),
            child: Text('Already have an account? Login'),
          ),
        ],
      ),
    );
  }
}
