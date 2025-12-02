import 'package:chat_app/controllers/user_controller.dart';
import 'package:get/get.dart';   

import '../controllers/auth_controller.dart';
import '../services/socket_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    //* 1. Put SocketService first (it needs to be alive always)
    Get.put(SocketService(), permanent: true);

    //* 2. Put AuthController (it uses SocketService)
    Get.put(AuthController(), permanent: true);

    //* 3. Put UserController
    Get.put(UserController(),permanent: true);

    
  }
}
