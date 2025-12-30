import 'package:chat_app/services/cache_services.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class HomeController extends GetxController {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = Get.find<SocketService>();
  final AuthController _authController = Get.find<AuthController>();
  final CacheService _cacheService = Get.find<CacheService>();

  var chatRooms = <ChatRoomModel>[].obs;
  var allUsers = <UserModel>[].obs;
  var isLoading = false.obs;
  var isLoadingUsers = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChatRooms();

    //* listen for live updates
    _listenForNewMessages();

    //* listen for status updates
    //_listenForStatusUpdates();
  }

  //* Load chat rooms with caching
  void fetchChatRooms({bool forceRefresh = false}) async {
    isLoading.value = true;

    try {
      //* Try to load from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedRooms = _cacheService.getCachedChatRooms();
        if (cachedRooms != null && cachedRooms.isNotEmpty) {
          chatRooms.value = cachedRooms;
          isLoading.value = false;

          //* Fetch fresh data in background
          _fetchChatRoomsFromAPI(updateInBackground: true);
          return;
        }
      }

      await _fetchChatRoomsFromAPI();
    } catch (e) {
      print("Error fetching chat rooms: $e");
    } finally {
      isLoading.value = false;
    }
  }

  //* Helper method to fetch from API
  Future<void> _fetchChatRoomsFromAPI({bool updateInBackground = false}) async {
    try {
      final response = await _apiService.getChatRooms();
      List<dynamic> data = response.data;

      final rooms = data.map((e) => ChatRoomModel.fromJson(e)).toList();

      //* Update cache
      await _cacheService.cacheChatRooms(rooms);

      chatRooms.value = rooms;

      if (updateInBackground) {
        print("✅ Chat rooms updated in background");
      }
    } catch (e) {
      print("Error fetching chat rooms from API: $e");
      rethrow;
    }
  }

  //* Load all users with caching
  void fetchAllUsers({bool forceRefresh = false}) async {
    isLoadingUsers.value = true;

    try {
      //* Try to load from cache first
      if (!forceRefresh) {
        final cachedUsers = _cacheService.getCachedAllUsers();
        if (cachedUsers != null && cachedUsers.isNotEmpty) {
          allUsers.value = cachedUsers;
          isLoadingUsers.value = false;

          //* Fetch fresh data in background
          _fetchAllUsersFromAPI(updateInBackground: true);
          return;
        }
      }

      //* If no cache or force refresh, fetch from API
      await _fetchAllUsersFromAPI();
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isLoadingUsers.value = false;
    }
  }

  //* Helper method to fetch users from API
  Future<void> _fetchAllUsersFromAPI({bool updateInBackground = false}) async {
    try {
      final response = await _apiService.getAllUsers();
      List<dynamic> data = response.data['allUsers'];

      final users = data.map((e) => UserModel.fromJson(e)).toList();

      //* Update cache
      await _cacheService.cacheAllUsers(users);

      allUsers.value = users;

      if (updateInBackground) {
        print("✅ All users updated in background");
      }
    } catch (e) {
      print("Error fetching users from API: $e");
      rethrow;
    }
  }

  //* Get user by ID with caching
  Future<UserModel?> getUserById(String userId) async {
    UserModel? cachedUser = _cacheService.getCachedUser(userId);
    if (cachedUser != null) {
      return cachedUser;
    }

    //* If not in cache, check if it's in allUsers list
    final user = allUsers.firstWhereOrNull((u) => u.userId == userId);
    if (user != null) {
      await _cacheService.cacheUser(user);
      return user;
    }

    return null;
  }

  //* listen for real-time events
  void _listenForNewMessages() {
    _socketService.socket.on('new_message_notification', (data) async {
      String senderId = data['senderId'];
      String message = data['message'];
      String senderName = data['senderName'];

      int index =
          chatRooms.indexWhere((room) => room.chatRoomId == data['roomId']);

      if (index != -1) {
        ChatRoomModel room = chatRooms[index];
        room.latestMessage = message;
        room.latestMessageTime = DateTime.now().toIso8601String();
        room.unreadCount = (room.unreadCount ?? 0) + 1;

        chatRooms.removeAt(index);
        chatRooms.insert(0, room);

        //* Update cache
        await _cacheService.updateChatRoomInCache(room);
      } else {
        ChatRoomModel newRoom = ChatRoomModel(
            userId: senderId,
            username: senderName,
            latestMessage: message,
            latestMessageTime: DateTime.now().toIso8601String(),
            unreadCount: 1,
            latestMessageStatus: "delivered");

        chatRooms.insert(0, newRoom);

        //* Update cache with new room
        await _cacheService.cacheChatRooms(chatRooms);
      }

      chatRooms.refresh();
    });
  }

  //* Listen for message status updates
  void handleStatusUpdate(Map<String, dynamic> data) async {
    var logger = Logger();
    logger.d(data);

    int index = chatRooms.indexWhere((room) => room.userId == data['receiver']);

    if (index != -1) {
      var room = chatRooms[index];
      room.latestMessageStatus = data['status'];
      chatRooms[index] = room;
      chatRooms.refresh();

      //* Update cache
      await _cacheService.updateChatRoomInCache(room);
    }
  }

  void markChatAsReadOnUI(String partnerId) async {
    int index = chatRooms.indexWhere((r) => r.userId == partnerId);
    if (index != -1) {
      var room = chatRooms[index];
      room.unreadCount = 0;
      chatRooms[index] = room;
      chatRooms.refresh();

      //* Update cache
      await _cacheService.updateChatRoomInCache(room);
    }
  }

  //* Clear cache on logout
  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
  }

  String get myUserId => _authController.myUserId ?? "";
}
