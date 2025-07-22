import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsController extends GetxController {
  var contacts = <Contact>[].obs;
  var isLoading = false.obs;
  var permissionGranted = false.obs;

  Future<void> fetchContacts(BuildContext context) async {
    isLoading.value = true;
    permissionGranted.value = await FlutterContacts.requestPermission();
    if (permissionGranted.value) {
      final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      contacts.value = fetchedContacts;
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Permission Required'),
          content: Text('Please allow contact permission to show your contacts.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                permissionGranted.value = await FlutterContacts.requestPermission();
                if (permissionGranted.value) {
                  final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
                  contacts.value = fetchedContacts;
                }
              },
              child: Text('Allow'),
            ),
          ],
        ),
      );
    }
    isLoading.value = false;
  }
}

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late final ContactsController controller;
  final TextEditingController _contactSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize GetX controller safely
    try {
      controller = Get.find<ContactsController>();
    } catch (e) {
      controller = Get.put(ContactsController());
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchContacts(context);
    });
  }

  @override
  void dispose() {
    _contactSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              if (!controller.permissionGranted.value) {
                return Center(child: Text('Contact permission not granted'));
              }
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
                physics: BouncingScrollPhysics(),
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