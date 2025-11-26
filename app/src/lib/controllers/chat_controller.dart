import 'dart:async';

import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/models/chat_room_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  //* Dependencies
  final SocketService _socketService = Get.find<SocketService>();
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  //* Variables passed from Home Screen
  late String partnerId;
  late String partnerName;
  late String myUserId;
  late String profileURL;

  //* Pagination
  int currentPage = 1;
  var isMoreLoading = false.obs;
  var hasMoreMessages = true.obs;

  //* State
  var messages = <MessageModel>[].obs;
  var isTyping = false.obs;
  var isPartnerOnline = false.obs;
  var lastSeen = "".obs;

  //* UI Controllers
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  //* helper functions
  String getRoomId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort();
    return users.join("_");
  }

  Timer? _typingTimer;
  bool _isTypingEmitted = false;

  @override
  void onInit() {
    super.onInit();

    //* 1. Get Arguments passed from Get.toNamed('/chat', arguments: {...})
    final args = Get.arguments as Map<String, dynamic>;
    // var logger = Logger();
    // logger.d(args);
    partnerId = args['partnerId'];
    partnerName = args['partnerName'];
    profileURL = args['partnerURL'];
    myUserId = _authController.myUserId!;

    //* 2. Join Room
    _socketService.joinRoom(myUserId, partnerId);

    //* 3. Load History
    loadMessages();

    //* 4. Listen for events
    _setupSocketListeners();

    markMessagesAsRead();

    //* scroll controller listener
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels == scrollCtrl.position.maxScrollExtent) {
        loadMessages();
      }
    });
  }

  //* load messages (supports pagination)
  void loadMessages({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      hasMoreMessages.value = true;
      messages.clear();
    }

    if (isMoreLoading.value || !hasMoreMessages.value) return;

    isMoreLoading.value = true;

    const int limit = 20;

    try {
      final response =
          await _apiService.getMessages(myUserId, partnerId, currentPage);

      if (response.data != null && response.data is List) {
        List<dynamic> data = response.data;

        List<MessageModel> newMessages = data
            .map((json) => MessageModel.fromJson(json, myUserId: myUserId))
            .toList();

        if (newMessages.length < limit) {
          hasMoreMessages.value = false;
        }

        if (newMessages.isNotEmpty) {
          messages.addAll(newMessages);
          currentPage++;
        }
      } else {
        hasMoreMessages.value = false;
      }
    } catch (e) {
      print("Error loading messages: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  void _setupSocketListeners() {
    final socket = _socketService.socket;

    //* A. New Message Received
    socket.on('new_message', (data) {
      //* Only process if it belongs to THIS conversation
      if (data['sender'] == partnerId) {
        MessageModel msg = MessageModel.fromJson(data, myUserId: myUserId);
        messages.insert(0, msg);

        markMessagesAsRead();
      } else {
        String newStatus = data['status'];
        String msgId = data['messageId'];

        var index = messages.indexWhere((m) => m.messageId == msgId);
        if (index != -1) {
          // Only update if status is different (e.g., 'sent' -> 'delivered')
          if (messages[index].status != newStatus) {
            messages[index].status = newStatus;
            messages.refresh();
          }
        }
      }
    });

    //* C. Typing & Online Status
    socket.on('typing_indicator', (data) {
      if (data['userId'] == partnerId) {
        isTyping.value = data['isTyping'];
      }
    });

    socket.on('user_status', (data) {
      if (data['userId'] == partnerId) {
        if (data['status'] == 'online') {
          isPartnerOnline.value = true;
        } else {
          isPartnerOnline.value = false;
          lastSeen.value = data['lastSeen'] ?? "";
        }
      }
    });

    socket.on('messages_all_read', (data) {
      if (data['reader'] == partnerId) {
        // Update all my 'sent'/'delivered' messages to 'read' locally
        for (var msg in messages) {
          if (msg.isMine && msg.status != 'read') {
            msg.status = 'read';
          }
        }
        messages.refresh();
      }
    });
  }

  //* B. Message Status Updated (Sent -> Delivered -> Read)
  void handleStatusUpdate(Map<String, dynamic> data) {
    var index = messages.indexWhere((m) => m.messageId == data['messageId']);
    if (index != -1) {
      if (messages[index].status != data['status']) {
        messages[index].status = data['status'];
        messages.refresh();
      }
    }
  }

  void markMessagesAsRead() {
    _socketService.socket.emit(
        'mark_messages_read', {'userId': myUserId, 'partnerId': partnerId});
  }

  void sendMessage() {
    String text = textCtrl.text.trim();
    if (text.isEmpty) return;

    //* 1. Generate ID
    String msgId = const Uuid().v4();

    //* 2. Optimistic Update (Add to UI immediately)
    MessageModel localMsg = MessageModel(
      messageId: msgId,
      sender: myUserId,
      receiver: partnerId,
      message: text,
      status: "sent",
      createdAt: DateTime.now(),
      isMine: true,
    );
    messages.insert(0, localMsg);
    textCtrl.clear();

    //* 3. Send to Server
    _socketService.sendMessage({
      "messageId": msgId,
      "sender": myUserId,
      "receiver": partnerId,
      "message": text,
    });

    //* 4. Update chatRoom's latest message
    if (Get.isRegistered<HomeController>()) {
      final HomeController homeController = Get.find<HomeController>();

      //* Find if this chat already exists in the list
      int index = homeController.chatRooms
          .indexWhere((room) => room.userId == partnerId);

      if (index != -1) {
        var room = homeController.chatRooms[index];

        room.latestMessage = text;
        room.latestMessageTime = DateTime.now().toIso8601String();
        room.latestMessageStatus = "sent";
        room.unreadCount = 0;

        room.messageId = msgId;

        //* Remove from old position and add to Top
        homeController.chatRooms.removeAt(index);
        homeController.chatRooms.insert(0, room);
      } else {
        var newRoom = ChatRoomModel(
          userId: partnerId,
          username: partnerName,
          latestMessage: text,
          latestMessageTime: DateTime.now().toIso8601String(),
          latestMessageStatus: "sent",
          unreadCount: 0,
          messageId: msgId,
        );

        homeController.chatRooms.insert(0, newRoom);
      }

      //* Force the Home UI to redraw
      homeController.chatRooms.refresh();
    }
  }

  void onTypingChange(String val) {
    //* Logic to send typing start/end only when status changes

    if (val.isEmpty) {
      _stopTyping();
      return;
    }

    if (!_isTypingEmitted) {
      _socketService.sendTyping(myUserId, partnerId, true);
      _isTypingEmitted = true;
    }

    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTypingEmitted) {
      _socketService.sendTyping(myUserId, partnerId, false);
      _isTypingEmitted = false;
    }
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
  }

  @override
  void onClose() {
    final socket = _socketService.socket;
    socket.off('new_message');
    // socket.off('message_status');
    socket.off('typing_indicator');
    socket.off('user_status');
    socket.off('messages_all_read');

    _socketService.leaveRoom(myUserId, partnerId);

    _stopTyping(); // * Ensure we don't leave a "typing..." status hanging
    super.onClose();
  }
}
