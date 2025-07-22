import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatController extends GetxController {
  var chats = <ChatModel>[].obs;
  var isLoading = false.obs;

  void fetchChats(String userId) {
    isLoading.value = true;
    FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      chats.value = snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
      isLoading.value = false;
    });
  }
}
