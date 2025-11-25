import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = Get.find<SocketService>();
  final _storage = const FlutterSecureStorage();

  RxBool isPasswordHidden = false.obs;

  var isLoading = false.obs;
  String? myUserId;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  //* Check if user is already logged in when app starts
  void checkLoginStatus() async {
    String? token = await _storage.read(key: 'token');
    String? userId = await _storage.read(key: 'userId');

    if (token != null && userId != null) {
      myUserId = userId;
      //* Re-connect socket immediately
      _socketService.initConnection(userId);
      Get.offAllNamed('/home'); // Go to Chat List
    } else {
      Get.offAllNamed('/landing');
    }
  }

  Future<void> register(String username, String password) async {
    isLoading.value = true;
    try {
      final response = await _apiService.register(username, password);
      if (response.statusCode == 201) {
        Get.snackbar("Success", "Account created! Please Login.");
        // Optional: Auto-login here if you want
        Get.offNamed('/login');
      }
    } catch (e) {
      Get.snackbar("Error", "Registration failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String username, String password) async {
    isLoading.value = true;
    try {
      final response = await _apiService.login(username, password);

      if (response.statusCode == 200) {
        final data = response.data;
        String token = data['token'];
        String userId = data['userId'];

        //* 1. Save securely
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'userId', value: userId);

        myUserId = userId;

        //* 2. Connect Socket
        _socketService.initConnection(userId);

        //* 3. Navigate
        Get.offAllNamed('/home');
      }
    } catch (e) {
      Get.snackbar("Error", "Login failed. Check credentials.");
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await _storage.deleteAll();
    _socketService.disconnect();
    Get.offAllNamed('/login');
  }
}
