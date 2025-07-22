import 'package:get/get.dart';

class ControllerBindings extends Bindings {
  @override
  void dependencies() {
    // These controllers will be initialized when needed
    // and properly disposed when not in use
  }
}

// Mixin to handle safe controller initialization
mixin SafeControllerInit {
  T getController<T extends GetxController>(T Function() builder) {
    try {
      return Get.find<T>();
    } catch (e) {
      return Get.put<T>(builder(), permanent: false);
    }
  }
}
