import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    isLoading.value = true;
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    users.value = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    isLoading.value = false;
  }
}
