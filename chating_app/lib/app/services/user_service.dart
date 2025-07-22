import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_user.dart';

class UserService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current user
  Rx<ChatUser?> currentUser = Rx<ChatUser?>(null);
  
  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    
    // Check if username contains only allowed characters
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;
    
    try {
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return result.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Create user with username
  Future<bool> createUserWithUsername({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? mobile, // Added mobile parameter
    String? bio,
  }) async {
    try {
      // Check if username is available
      if (!await isUsernameAvailable(username)) {
        Get.snackbar(
          'Error',
          'Username is not available',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
      
      // Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Create user document in Firestore
        final chatUser = ChatUser(
          uid: userCredential.user!.uid,
          username: username.toLowerCase(),
          displayName: displayName,
          email: email,
          mobile: mobile, // Added mobile to ChatUser creation
          bio: bio,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(chatUser.toJson());
        
        // Update current user
        currentUser.value = chatUser;
        
        Get.snackbar(
          'Success',
          'Account created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        return true;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    
    return false;
  }
  
  // Search users by username
  Future<List<ChatUser>> searchUsersByUsername(String query) async {
    if (query.length < 2) return [];
    
    try {
      final result = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();
      
      return result.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) => user.uid != _auth.currentUser?.uid) // Exclude current user
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search users by display name
  Future<List<ChatUser>> searchUsersByDisplayName(String query) async {
    if (query.length < 2) return [];
    
    try {
      final result = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .limit(20)
          .get();
      
      return result.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) => user.uid != _auth.currentUser?.uid)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get current user data
  Future<ChatUser?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (doc.exists) {
        final user = ChatUser.fromJson(doc.data()!);
        currentUser.value = user;
        return user;
      }
    } catch (e) {
      print('Error getting current user data: $e');
    }
    
    return null;
  }
  
  // Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
  
  // Get user by username
  Future<ChatUser?> getUserByUsername(String username) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      if (result.docs.isNotEmpty) {
        return ChatUser.fromJson(result.docs.first.data());
      }
    } catch (e) {
      print('Error getting user by username: $e');
    }
    
    return null;
  }
  
  // Get user by UID
  Future<ChatUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return ChatUser.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error getting user by UID: $e');
    }
    
    return null;
  }
}
