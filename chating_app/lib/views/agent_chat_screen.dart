import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/agent_chat_controller.dart';

class AgentChatScreen extends StatelessWidget {
  final chatController = Get.put(AgentChatController());
  final msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Chat')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              reverse: false,
              itemCount: chatController.messages.length,
              itemBuilder: (_, i) {
                final msg = chatController.messages[i];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isUser)
                              Icon(Icons.support_agent, size: 18, color: Colors.blueGrey),
                            Text(isUser ? 'You' : 'Agent',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(msg.message, style: TextStyle(fontSize: 16)),
                        SizedBox(height: 4),
                        Text(
                          "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(hintText: 'Type your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final text = msgController.text.trim();
                    if (text.isNotEmpty) {
                      chatController.sendUserMessage(text);
                      msgController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
