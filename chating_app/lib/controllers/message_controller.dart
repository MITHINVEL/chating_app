import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageController extends GetxController {
  var messages = <MessageModel>[].obs;
  var isLoading = false.obs;

  void fetchMessages(String chatId) async {
    isLoading.value = true;
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();
    messages.value = snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
    isLoading.value = false;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final message = MessageModel(
      messageId: '',
      senderId: senderId,
      text: text,
      timestamp: Timestamp.now(),
    );
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    });
  }
}
