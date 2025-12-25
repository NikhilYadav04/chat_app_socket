import 'dart:async';
import 'dart:io';

import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/models/chat_room_model.dart';
import 'package:chat_app/views/chat/audi_record_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  var isUploading = false.obs;
  var isFetching = false.obs;

  Rx<File?> uploadMedia = Rx<File?>(null);
  Rx<String> uploadedURL = "".obs;
  Rx<String> uploadedPublicId = "".obs;

  //* UI Controllers
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  //* helper functions
  String getRoomId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort();
    return users.join("_");
  }

//* <------- PICK IMAGE --------------->
  void pickImage() async {
    final ImagePicker picker = ImagePicker();

    //* Show source selection dialog
    final ImageSource? source = await Get.dialog<ImageSource>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              _buildSourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              _buildSourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    //* Pick image
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    uploadMedia.value = File(pickedFile.path);
  }

//* < --------- PICK AUDIO ----------------->
  void pickAudio() async {
    final audioPath = await Get.dialog<String>(
      AudioRecordingDialog(),
      barrierDismissible: false,
    );

    if (audioPath != null) {
      print('Audio saved at: $audioPath');
      uploadMedia.value = File(audioPath);

      //* After successful upload, delete the file
      // try {
      //   final file = File(audioPath);
      //   if (await file.exists()) {
      //     await file.delete();
      //     print('Audio file deleted successfully');
      //   }
      // } catch (e) {
      //   print('Error deleting audio file: $e');
      // }
    } else {
      Get.snackbar(
        '⚠️ Audio Recording Error',
        'Error recording error !!',
        backgroundColor: Colors.orange.shade700,
        colorText: AppColors.white,
        icon: const Icon(
          Icons.file_present_rounded,
          color: AppColors.white,
        ),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        isDismissible: true,
      );
    }
  }

//* <------------- DELETE FILE -------------->
  void removeFile() async {
    File? fileToDelete = uploadMedia.value;

    uploadMedia.value = null;

    if (fileToDelete != null) {
      try {
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
          print(
              "🗑️ Temporary file deleted successfully: ${fileToDelete.path}");
        }
      } catch (e) {
        print("⚠️ Error deleting file: $e");
      }
    }
  }
  //* < -------------------------------------->

  //* typing status utils
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

    if (currentPage == 1) {
      isFetching.value = true;
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
      isFetching.value = false;
    }
  }

  //* Setup listeners for socket events
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

    //* Message edited ( Success and failure )
    socket.on('message_edited', (data) {
      final msgId = data['id'];
      final newMessage = data['text'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (!messages[index].isMine) {
          messages[index].isEdited = true;
          messages[index].message = newMessage;
          messages.refresh();
        }
      }
    });

    socket.on('message_edited_error', (data) {
      final msgId = data['id'];
      final text = data['text'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (messages[index].isMine) {
          messages[index].isEdited = false;
          messages[index].message = text;

          messages.refresh();
        }
      } else {
        Get.snackbar(
          '❌ Failed to Edit',
          'Message could not be edited. Please check your connection and try again.',

          backgroundColor: Colors.red.shade700,
          colorText: AppColors.white,
          icon: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.white,
          ),

          // --- UX Improvements ---
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
          isDismissible: true,
        );
      }
    });

    //* Message deleted ( Success and failure )
    socket.on('message_deleted', (data) {
      final msgId = data['id'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (!messages[index].isMine) {
          messages[index].isDeleted = true;
          messages.refresh();
        }
      }
    });

    socket.on('message_deleted_error', (data) {
      final msgId = data['id'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (messages[index].isMine) {
          messages[index].isDeleted = false;

          messages.refresh();
        }
      } else {
        Get.snackbar(
          '❌ Failed to Delete',
          'Message could not be deleted. Please check your connection and try again.',

          backgroundColor: Colors.red.shade700,
          colorText: AppColors.white,
          icon: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.white,
          ),

          // --- UX Improvements ---
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
          isDismissible: true,
        );
      }
    });

    //* message liked ( Success and failure )
    socket.on('message_liked', (data) {
      final msgId = data['id'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (messages[index].isMine) {
          messages[index].isLiked = true;
          messages.refresh();
        }
      }
    });

    socket.on('message_liked_error', (data) {
      final msgId = data['id'];

      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (!messages[index].isMine) {
          messages[index].isLiked = false;

          messages.refresh();
        }
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

  //* <--------------- SEND, DELETE, LIKE , EDIT MESSAGE -------------------- >

  void sendMessage(String repliedTo, String repliedMessage,
      {String? messageText = ""}) async {
    try {
      if (isUploading.value) {
        Get.snackbar(
          '❌ Unable to send another message',
          'Please wait for the previous message to go through.',

          backgroundColor: Colors.red.shade700,
          colorText: AppColors.white,
          icon: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.white,
          ),

          // --- UX Improvements ---
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
          isDismissible: true,
        );
      }

      isUploading.value = true;

      String text = textCtrl.text.trim();

      //* default message type is text
      String type = "text";

      //* is media message
      if (uploadMedia.value != null && uploadMedia.value!.path.isNotEmpty) {
        type = (uploadMedia.value!.path.toString().endsWith(".jpg") ||
                uploadMedia.value!.path.toString().endsWith(".png"))
            ? "image"
            : (uploadMedia.value!.path.toString().endsWith(".mp3") ||
                    uploadMedia.value!.path.toString().endsWith(".wav") ||
                    uploadMedia.value!.path.toString().endsWith(".m4a"))
                ? "audio"
                : "text";
      }

      //* Check for empty message content
      if (text.isEmpty && type == "text" && messageText!.isEmpty) return;

      //* 1. Generate ID
      String msgId = const Uuid().v4();

      //* add message bubble with loader
      MessageModel tempMessage = MessageModel(
          messageId: msgId,
          sender: myUserId,
          receiver: partnerId,
          message: messageText!.isNotEmpty
              ? messageText
              : text.trim() == "" && type != "text"
                  ? "${type}"
                  : text,
          status: "sending",
          fileURL: "",
          publicId: "",
          messageType: messageText.isNotEmpty ? "call" : type,
          createdAt: DateTime.now(),
          isMine: true,
          repliedTo: repliedTo,
          repliedMessage: repliedMessage);
      messages.insert(0, tempMessage);

      var logger = Logger();

      logger.d(type);

      if (type != "text" && type != "call") {
        String response = await uploadMessageMedia();

        if (response != "success") {
          messages.removeAt(0);
          Get.snackbar(
            '❌ Failed to Send',
            'Message was not sent. Please check your connection and try again.',

            backgroundColor: Colors.red.shade700,
            colorText: AppColors.white,
            icon: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.white,
            ),

            // --- UX Improvements ---
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 4),
            isDismissible: true,
          );
          return;
        }
      }

      //* 2. update the message bubble with status change and media (if present )
      final index = messages.indexWhere((msg) => msg.messageId == msgId);

      if (index != -1) {
        if (type != "text") {
          messages[index].fileURL =
              uploadedURL.value != "" ? uploadedURL.value : "";
          messages[index].publicId =
              uploadedPublicId.value == "" ? "" : uploadedPublicId.value;
        }
      }

      textCtrl.clear();

      //* 3. Send to Server

      type == "text" && messageText.isEmpty
          ? _socketService.sendMessage({
              "messageId": msgId,
              "sender": myUserId,
              "receiver": partnerId,
              "message": text,
              "repliedMessage": repliedMessage,
              "repliedTo": repliedTo
            })
          : messageText.isNotEmpty
              ? _socketService.sendMessage({
                  "messageId": msgId,
                  "sender": myUserId,
                  "receiver": partnerId,
                  "message": messageText,
                  "repliedMessage": repliedMessage,
                  "repliedTo": repliedTo,
                  "messageType": "call"
                })
              : _socketService.sendMessage({
                  "messageId": msgId,
                  "sender": myUserId,
                  "receiver": partnerId,
                  "message": tempMessage.message,
                  "messageType": type,
                  "fileURL": uploadedURL.value != "" ? uploadedURL.value : "",
                  "filePublicId": uploadedPublicId.value == ""
                      ? ""
                      : uploadedPublicId.value,
                  "repliedMessage": repliedMessage,
                  "repliedTo": repliedTo
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

          messages.refresh();

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
    } catch (e) {
      print(e);
    } finally {
      isUploading.value = false;
      removeFile();
      uploadedPublicId.value = "";
      uploadedURL.value = "";
    }
  }

  void likeMessage(String id, bool isMine) {
    if (id.isEmpty || isMine) {
      return;
    }

    final index = messages.indexWhere((msg) => msg.messageId == id);

    if (index == -1) {
      return;
    }

    _socketService.likeMessage(
        id, messages[index].sender!, messages[index].receiver!);

    messages[index].isLiked = true;
    messages.refresh();
  }

  void deleteMessage(String id, bool isMine) {
    if (id.isEmpty || !isMine) {
      return;
    }

    final index = messages.indexWhere((msg) => msg.messageId == id);

    if (index == -1) {
      return;
    }

    _socketService.deleteMessage(
        id, messages[index].sender!, messages[index].receiver!);

    messages[index].isDeleted = true;
    messages.refresh();
  }

  void editMessage(String id, bool isMine, String text) {
    if (id.isEmpty || !isMine) {
      return;
    }

    final index = messages.indexWhere((msg) => msg.messageId == id);

    if (index == -1) {
      return;
    }

    _socketService.editMessage(
        id, text, messages[index].sender!, messages[index].receiver!);

    messages[index].isEdited = true;
    messages[index].message = text.trim();
    messages.refresh();
  }

  //* <------------------------------------------------------------------------->

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

  //* Upload Media
  Future<String> uploadMessageMedia() async {
    try {
      final response = await _apiService.uploadMessageMedia(uploadMedia.value!);

      if (response.statusCode != 200) {
        throw Exception("Error uploading media");
      }

      final responseMap = response.data;

      uploadedURL.value = responseMap["url"];
      uploadedPublicId.value = responseMap["public_id"];

      return "success";
    } catch (e) {
      print(e);
      return "Error : ${e.toString()}";
    }
  }

  //* build media options
  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
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
