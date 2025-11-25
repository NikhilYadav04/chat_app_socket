import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService {
  late IO.Socket socket;

  static const String _socketUrl = 'http://192.168.56.1:3000';

  //* We call this after Login is successful
  void initConnection(String userId) {
    socket = IO.io(
      _socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Socket Connected to Backend');

      socket.emit('register_user', {'userId': userId});
    });

    //* handling notifications
    _setupGlobalListeners();

    socket.onDisconnect((_) => print('❌ Socket Disconnected'));
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
      Get.snackbar(
        "New Message from $senderName",
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black87,
        icon: const Icon(Icons.chat_bubble, color: Colors.blue),
        duration: const Duration(seconds: 4),
        isDismissible: true,

        onTap: (_) {
          // If we are already in a chat, this replaces it.
          // If we are home, it pushes the chat.
          Get.toNamed('/chat', arguments: {
            'partnerId': senderId,
            'partnerName': senderName,
          });
        },

        // // Optional: Add a 'Reply' button
        // mainButton: TextButton(
        //   onPressed: () {
        //     Get.toNamed('/chat', arguments: {
        //       'partnerId': senderId,
        //       'partnerName': senderName,
        //     });
        //   },
        //   child: const Text("REPLY"),
        // ),
      );
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
    socket.emit('join_room', {
      'userId': myId,
      'partnerId': partnerId,
    });
  }

  //* Leave a chat room
  void leaveRoom(String myId, String partnerId) {
    socket.emit('leave_room', {
      'userId': myId,
      'partnerId': partnerId,
    });
  }

  //* Send a text message
  void sendMessage(Map<String, dynamic> messageData) {
    socket.emit('send_message', messageData);
  }

  //* Send typing status
  void sendTyping(String myId, String partnerId, bool isTyping) {
    String event = isTyping ? 'typing_start' : 'typing_end';
    socket.emit(event, {
      'userId': myId,
      'receiverId': partnerId,
    });
  }

  //* Clean up
  void disconnect() {
    socket.disconnect();
  }
}
