import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/notification_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService with WidgetsBindingObserver {
  late IO.Socket socket;

  //* Safety flag to prevent crashes if app pauses before login
  bool _isInitialized = false;

  static const String _socketUrl = 'http://192.168.56.1:3000';

  //* Register the Observer when the Service starts
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  //* Remove the Observer when the Service dies 👇
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  //* 4. Handle Background/Foreground changes 👇
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //* If the user hasn't logged in yet, 'socket' isn't real. Do nothing.
    if (!_isInitialized) return;

    if (state == AppLifecycleState.paused) {
      print(
          "🌗 App Paused (Background) - Disconnecting Socket to save battery...");
      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      print("☀️ App Resumed (Foreground) - Reconnecting Socket...");
      if (!socket.connected) {
        socket.connect();

        final _secureStorage = const FlutterSecureStorage();
        String? userId = await _secureStorage.read(key: 'userId');

        //* ONLY emit if we found an ID and the socket is ready
        if (userId != null) {
          //* We use onConnect one-time listener to ensure we are connected before emitting
          socket.on('connect', (_) {
            socket.emit('register_user', {'userId': userId});
          });
        }
      }
    }
  }

  //* We call this after Login is successful
  void initConnection(String userId) {
    try {
      socket.dispose();
      socket.destroy();
    } catch (e) {}

    var logger = Logger();
    logger.d("Called for user ${userId}");
    socket = IO.io(
      _socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    _isInitialized = true;

    socket.onConnect((_) {
      print('✅ Socket Connected to Backend');

      socket.emit('register_user', {'userId': userId});
    });

    //* handling notifications
    _setupGlobalListeners();

    socket.onDisconnect((_) {
      print('❌ Socket Disconnected');
      socket.emit('manual_disconnect');
    });
    socket.onConnectError((err) => print('⚠️ Socket Error: $err'));
  }

  //* ---- GLOBAL LISTENERS ------
  void _setupGlobalListeners() {
    //* Clear Old Listeners
    socket.off('new_message_notification');
    socket.off('pending_messages');

    socket.on('new_message_notification', (data) {
      String senderName = data['senderName'];
      String message = data['message'];
      String senderId = data['senderId'];

      print("✅ not");

      //* 2. Show In-App Notification (Snackbar)
      // Get.snackbar(
      //   "New Message from $senderName",
      //   message,
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.white,
      //   colorText: Colors.black87,
      //   icon: const Icon(Icons.chat_bubble, color: Colors.blue),
      //   duration: const Duration(seconds: 4),
      //   isDismissible: true,

      //   onTap: (_) {
      //     // If we are already in a chat, this replaces it.
      //     // If we are home, it pushes the chat.
      //     Get.toNamed('/chat', arguments: {
      //       'partnerId': senderId,
      //       'partnerName': senderName,
      //     });
      //   },

      //   // // Optional: Add a 'Reply' button
      //   // mainButton: TextButton(
      //   //   onPressed: () {
      //   //     Get.toNamed('/chat', arguments: {
      //   //       'partnerId': senderId,
      //   //       'partnerName': senderName,
      //   //     });
      //   //   },
      //   //   child: const Text("REPLY"),
      //   // ),
      // );
      NotificationConfig().showInstantNotification(
          receiver: senderName, message: message, id: senderId);
    });

    socket.on('message_status', (data) {
      print("📡 SOCKET SERVICE: Received Status Update: ${data['status']}");

      //* 1. Update Chat Screen (if open)
      if (Get.isRegistered<ChatController>()) {
        print("✅ regsiterdc chat");
        Get.find<ChatController>().handleStatusUpdate(data);
      }

      //* 2. Update Home Screen (if open)
      if (Get.isRegistered<HomeController>()) {
        print("✅ regsiterd home");
        Get.find<HomeController>().handleStatusUpdate(data);
      }
    });
  }

  //* --- HELPER METHODS ---

  //* Join a specific chat room
  void joinRoom(String myId, String partnerId) {
    if (!_isInitialized) return;
    socket.emit('join_room', {
      'userId': myId,
      'partnerId': partnerId,
    });
  }

  //* Leave a chat room
  void leaveRoom(String myId, String partnerId) {
    if (!_isInitialized) return;
    socket.emit('leave_room', {
      'userId': myId,
      'partnerId': partnerId,
    });
  }

  //* Send a text message
  void sendMessage(Map<String, dynamic> messageData) {
    if (!_isInitialized) return;
    socket.emit('send_message', messageData);
  }

  //* Send typing status
  void sendTyping(String myId, String partnerId, bool isTyping) {
    if (!_isInitialized) return;
    String event = isTyping ? 'typing_start' : 'typing_end';
    socket.emit(event, {
      'userId': myId,
      'receiverId': partnerId,
    });
  }

  //* Edit message
  void editMessage(
      String messageId, String text, String sender, String receiver) {
    if (!_isInitialized) return;
    socket.emit('edit_message', {
      'messageId': messageId,
      'text': text,
      'sender': sender,
      'receiver': receiver
    });
  }

  //* Delete message
  void deleteMessage(String messageId, String sender, String receiver) {
    if (!_isInitialized) return;
    socket.emit('delete_message',
        {'messageId': messageId, 'sender': sender, 'receiver': receiver});
  }

  //* Like message
  void likeMessage(String messageId, String sender, String receiver) {
    if (!_isInitialized) return;
    socket.emit('like_message',
        {'messageId': messageId, 'sender': sender, 'receiver': receiver});
  }

  //* Clean up
  void disconnect() {
    if (!_isInitialized) return;
    socket.emit('manual_disconnect');
    socket.disconnect();
  }
}
