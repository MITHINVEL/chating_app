import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agent_message.dart';

class AgentChatController extends GetxController {
  RxList<AgentMessage> messages = <AgentMessage>[].obs;
  late String uid;

  @override
  void onInit() {
    super.onInit();
    uid = FirebaseAuth.instance.currentUser!.uid;
    listenMessages();
  }

  void listenMessages() {
    FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('agent_messages')
      .orderBy('timestamp')
      .snapshots()
      .listen((snapshot) {
        messages.value = snapshot.docs.map((doc) => AgentMessage.fromMap(doc.data())).toList();
      });
  }

  Future<void> sendUserMessage(String text) async {
    final msg = AgentMessage(
      sender: 'user',
      message: text,
      timestamp: DateTime.now(),
    );
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('agent_messages')
      .add(msg.toMap());

    // Simulate agent reply after delay
    Future.delayed(Duration(seconds: 2), () => sendAgentReply());
  }

  Future<void> sendAgentReply() async {
    final reply = AgentMessage(
      sender: 'agent',
      message: "Thanks for your message. We'll get back soon.",
      timestamp: DateTime.now(),
    );
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('agent_messages')
      .add(reply.toMap());
  }
}
