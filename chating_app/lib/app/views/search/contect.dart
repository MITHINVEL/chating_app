import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsController extends GetxController {
  var contacts = <Contact>[].obs;
  var isLoading = false.obs;

  Future<void> fetchContacts() async {
    isLoading.value = true;
    if (await FlutterContacts.requestPermission()) {
      final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      contacts.value = fetchedContacts;
    }
    isLoading.value = false;
  }
}

class ContactsScreen extends StatelessWidget {
  final ContactsController controller = Get.put(ContactsController());
  final TextEditingController _contactSearchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    controller.fetchContacts();
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _contactSearchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.indigo[50],
              ),
              onChanged: (_) => controller.update(),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              final searchText = _contactSearchController.text.toLowerCase();
              final filteredContacts = controller.contacts.where((c) {
                final name = c.displayName.toLowerCase();
                final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
                return name.contains(searchText) || phone.contains(searchText);
              }).toList();
              if (filteredContacts.isEmpty) {
                return Center(child: Text('No contacts found'));
              }
              return ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, idx) {
                  final contact = filteredContacts[idx];
                  final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                  return ListTile(
                    leading: CircleAvatar(child: Text(contact.displayName.isNotEmpty ? contact.displayName[0] : '?')),
                    title: Text(contact.displayName),
                    subtitle: Text(phone),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
