import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgetPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          SvgPicture.asset('assets/images/forget.svg', height: 150),
          SizedBox(height: 20),
          Text('Forgot Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(labelText: 'Email or Mobile Number'),
          ),
          ElevatedButton(
            onPressed: () {}, // Send OTP or reset link logic
            child: Text('Send OTP/Reset Link'),
          ),
        ],
      ),
    );
  }
}
