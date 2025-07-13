import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:country_picker/country_picker.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  bool emailExistsError = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  String countryCode = '+91';

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        SizedBox(height: 20),
        Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        SizedBox(height: 30),
        SvgPicture.asset('assets/images/register.svg', height: 150),
        SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              SizedBox(height: 16),
              AnimatedContainer(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (Country country) {
                            setState(() {
                              countryCode = '+${country.phoneCode}';
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(countryCode, style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Enter mobile number' : null,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: emailExistsError ? Colors.red : Colors.grey),
                  ),
                  errorText: emailExistsError ? 'Email already exists' : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? 'Enter email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                obscureText: true,
                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                obscureText: true,
                validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() { emailExistsError = false; });
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      // Store name and phone in Firestore
                      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                        'name': nameController.text,
                        'phone': countryCode + phoneController.text,
                        'email': emailController.text,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Get.snackbar('Success', 'Account created and data stored!', backgroundColor: Colors.green, colorText: Colors.white);
                      // Full refresh: clear all fields and reset form
                      nameController.clear();
                      phoneController.clear();
                      emailController.clear();
                      passwordController.clear();
                      confirmController.clear();
                      setState(() {
                        _formKey.currentState?.reset();
                        emailExistsError = false;
                      });
                    } catch (e) {
                      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
                        setState(() { emailExistsError = true; });
                      }
                      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  }
                },
                child: Text('Create Account'),
              ),
              Row(
                children: [
                  SizedBox(width: 8),
                  Text('Already have an account?',
                  style: TextStyle(fontSize: 16)),
                  TextButton(
                    
                    onPressed: () => Get.toNamed('/login'),
                    child: Text(' Login', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
