import 'package:chat_app/controllers/call_controller.dart';
import 'package:chat_app/controllers/stats_controller.dart';
import 'package:chat_app/controllers/user_controller.dart';
import 'package:chat_app/services/cache_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = Get.find<SocketService>();
  final CallController _callController = Get.find<CallController>();
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
      _callController.setupController(userId);
      Get.offAllNamed('/home'); // Go to Chat List
    } else {
      Get.offAllNamed('/landing');
    }
  }

  Future<void> register(
      String fullName, String username, String password) async {
    isLoading.value = true;
    try {
      final response = await _apiService.register(fullName, username, password);
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

        //* 2. Connect Socket and initialize call controller
        _socketService.initConnection(userId);
        _callController.setupController(userId);

        //* Get user details
        final _userController = Get.find<UserController>();
        await _userController.fetchUserData();

        //* 4. Navigate
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
    final UserController _userController = Get.find<UserController>();
    final CacheService _cacheService = Get.find<CacheService>();
    final statsController = Get.find<StatsController>();

    _userController.clear();
    await _storage.deleteAll();
    statsController.clear();

    //* Clear all cache
    await _cacheService.clearAllCache();

    _socketService.disconnect();
    _callController.onClose();
    Get.offAllNamed('/login');
  }
}
