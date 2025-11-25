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

  var chatRooms = <ChatRoomModel>[].obs;
  var allUsers = <UserModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChatRooms();

    //* listen for live updates
    _listenForNewMessages();

    //* listen for status updates
    //_listenForStatusUpdates();
  }

  //* Load the "WhatsApp-like" list of conversations
  void fetchChatRooms() async {
    isLoading.value = true;
    try {
      final response = await _apiService.getChatRooms();
      List<dynamic> data = response.data;

      chatRooms.value = data.map((e) => ChatRoomModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching chat rooms: $e");
    } finally {
      isLoading.value = false;
    }
  }

  //* Load all users to start a new chat
  void fetchAllUsers() async {
    try {
      final response = await _apiService.getAllUsers();
      List<dynamic> data = response.data['allUsers'];
      allUsers.value = data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  //* listen for real-time events
  void _listenForNewMessages() {
    _socketService.socket.on('new_message_notification', (data) {
      String senderId = data['senderId'];
      String message = data['message'];
      String senderName = data['senderName'];

      //* 1. Check if this user is already in our chat list
      int index =
          chatRooms.indexWhere((room) => room.chatRoomId == data['roomId']);

      if (index != -1) {
        //* CASE A: User exists in list. Update them.
        ChatRoomModel room = chatRooms[index];

        //* Update fields
        room.latestMessage = message;
        room.latestMessageTime = DateTime.now().toIso8601String();
        room.unreadCount = (room.unreadCount ?? 0) + 1; // Increase badge

        //* Remove from current position and add to TOP
        chatRooms.removeAt(index);
        chatRooms.insert(0, room);
      } else {
        //* CASE B: New conversation (User not in list yet)
        ChatRoomModel newRoom = ChatRoomModel(
            userId: senderId,
            username: senderName,
            latestMessage: message,
            latestMessageTime: DateTime.now().toIso8601String(),
            unreadCount: 1,
            latestMessageStatus: "delivered");

        chatRooms.insert(0, newRoom);
      }

      // *Refresh the list UI
      chatRooms.refresh();
    });
  }

  //* listen for message status updates
  void handleStatusUpdate(Map<String, dynamic> data) {
    // Find the room for the receiver (partner)
    var logger = Logger();

    logger.d(data);
    int index = chatRooms.indexWhere((room) => room.userId == data['receiver']);

    if (index != -1) {
      var room = chatRooms[index];
      // Update unconditionally (or check ID if you prefer)
      room.latestMessageStatus = data['status'];
      chatRooms[index] = room;
      chatRooms.refresh();
    }
  }

  void markChatAsReadOnUI(String partnerId) {
    int index = chatRooms.indexWhere((r) => r.userId == partnerId);
    if (index != -1) {
      var room = chatRooms[index];
      room.unreadCount = 0;
      chatRooms[index] = room;
      chatRooms.refresh();
    }
  }

  String get myUserId => _authController.myUserId ?? "";
}
