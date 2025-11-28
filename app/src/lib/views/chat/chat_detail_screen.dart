import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/views/chat/display_input_media.dart';
import 'package:chat_app/views/chat/empty_list_widget.dart';
import 'package:chat_app/views/chat/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_controller.dart';
import '../../constants/colors.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController chatController = Get.put(ChatController());

  //* For floating date indicator
  bool _showDateIndicator = false;
  String _currentDate = '';
  Timer? _hideTimer;

  //* For editing messages
  String? _editingMessageId;
  String? _editingMessageText;
  bool _isEditMode = false;

  //* For reply message
  String? _repliedMessage;
  String? _repliedTo;
  bool _isReplyMode = false;

  @override
  void initState() {
    super.initState();
    chatController.scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    chatController.scrollCtrl.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    //* Show date indicator while scrolling
    if (!_showDateIndicator) {
      setState(() {
        _showDateIndicator = true;
      });
    }

    //* Update current visible date
    _updateVisibleDate();

    //* Cancel previous timer and start new one
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showDateIndicator = false;
        });
      }
    });
  }

  void _updateVisibleDate() {
    if (chatController.messages.isEmpty) return;

    //* Get the scroll position
    final scrollOffset = chatController.scrollCtrl.offset;
    final viewportHeight = chatController.scrollCtrl.position.viewportDimension;

    //* Since list is reversed, calculate which message is at top of viewport
    final estimatedIndex =
        (scrollOffset / 60).floor(); // Approximate item height

    if (estimatedIndex >= 0 &&
        estimatedIndex < chatController.messages.length) {
      final message = chatController.messages[estimatedIndex];
      if (message.createdAt != null) {
        final newDate = _formatDateIndicator(message.createdAt!);
        if (newDate != _currentDate) {
          setState(() {
            _currentDate = newDate;
          });
        }
      }
    }
  }

  String _formatDateIndicator(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();

    if (localDate.day == now.day &&
        localDate.month == now.month &&
        localDate.year == now.year) {
      return 'Today';
    }

    if (localDate.day == now.day - 1 &&
        localDate.month == now.month &&
        localDate.year == now.year) {
      return 'Yesterday';
    }

    final difference = now.difference(localDate).inDays;
    if (difference < 7) {
      return DateFormat('EEEE').format(localDate); // Day name
    }

    if (localDate.year == now.year) {
      return DateFormat('dd MMMM').format(localDate);
    }

    return DateFormat('dd MMM yyyy').format(localDate);
  }

  //* <------------- EDIT MESSAGE ------------------------>

  void _startEditMode(String messageId, String currentText) {
    setState(() {
      _isEditMode = true;
      _editingMessageId = messageId;
      _editingMessageText = currentText;
      chatController.textCtrl.text = currentText;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (chatController.scrollCtrl.hasClients) {
        chatController.scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Focus on text field
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editingMessageId = null;
      _editingMessageText = null;
      _repliedTo = null;
      chatController.textCtrl.clear();
    });
  }

  void _submitEdit(String currentText) {
    if (_editingMessageId != null &&
        chatController.textCtrl.text.trim().isNotEmpty) {
      chatController.editMessage(_editingMessageId!, true, currentText.trim());
      _cancelEdit();
    }
  }

  //* <--------------------------------------------------------------->

  //* < ------------ REPLY MODE ------------------------>

  void _replyMode(String message, String repliedTo) {
    setState(() {
      _isReplyMode = true;
      _repliedMessage = message;
      _repliedTo = repliedTo;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (chatController.scrollCtrl.hasClients) {
        chatController.scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Focus on text field
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _replyModeCancel() {
    setState(() {
      _isReplyMode = false;
      _repliedMessage = "";
    });
  }
  //* <-------------------------------------------------->

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text, size: 20),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: (chatController.profileURL == null ||
                        chatController.profileURL!.isEmpty)
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: (chatController.profileURL != null &&
                      chatController.profileURL!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: chatController.profileURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Text(
                            chatController.partnerName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            chatController.partnerName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        chatController.partnerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatController.partnerName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  Obx(() {
                    if (chatController.isTyping.value) {
                      return const Text("Typing...",
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500));
                    }
                    if (chatController.isPartnerOnline.value) {
                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("Online",
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textLight)),
                        ],
                      );
                    }
                    if (chatController.lastSeen.value.isNotEmpty) {
                      return Text(
                          "Last seen: ${_formatLastSeen(chatController.lastSeen.value)}",
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textLight));
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Obx(() {
                  //* 1. Initial Loading State
                  if (chatController.isFetching.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  //* 2. Empty State (Not loading, and list is empty)
                  if (chatController.messages.isEmpty) {
                    return buildEmptyState(chatController.partnerName);
                  }

                  //* 3. Data Loaded (Show List)
                  return ListView.separated(
                    reverse: true,
                    controller: chatController.scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    separatorBuilder: (ctx, i) => const SizedBox(height: 2),
                    itemCount: chatController.messages.length +
                        (chatController.isMoreLoading.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatController.messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2),
                          ),
                        );
                      }

                      final msg = chatController.messages[index];
                      return GestureDetector(
                        onDoubleTap: () {
                          if (!msg.isLiked!) {
                            chatController.likeMessage(
                                msg.messageId!, msg.isMine);
                          }
                        },
                        child: MessageBubble(
                          msg: msg,
                          onDelete: () {
                            chatController.deleteMessage(
                                msg.messageId!, msg.isMine);
                          },
                          onEdit: () {
                            _startEditMode(
                              msg.messageId!,
                              msg.message ?? '',
                            );
                          },
                          onReply: () {
                            _replyMode(
                                msg.message!,
                                msg.isMine
                                    ? "Me"
                                    : "${chatController.partnerName}");
                          },
                          key: ValueKey(msg.messageId),
                        ),
                      );
                    },
                  );
                }),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //* Edit Mode Banner
                      if (_isEditMode)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Edit Message',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _editingMessageText ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.text.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                onPressed: _cancelEdit,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      //* Reply Mode Banner
                      if (_isReplyMode)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.reply,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reply To Message',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _repliedMessage ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.text.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                onPressed: _replyModeCancel,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      //* File preview (above input)
                      if (!_isEditMode)
                        Obx(() {
                          if (chatController.uploadMedia.value != null) {
                            String path =
                                chatController.uploadMedia.value?.path ?? "";

                            // Check file types
                            bool isImage = path.endsWith(".jpg") ||
                                path.endsWith(".jpeg") ||
                                path.endsWith(".png");

                            bool isAudio = path.endsWith(".mp3") ||
                                path.endsWith(".wav") ||
                                path.endsWith(".m4a") ||
                                path.endsWith(".aac");

                            // 1. AUDIO PREVIEW
                            if (isAudio) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: AudioPreviewInline(
                                  file: chatController.uploadMedia.value!,
                                  onRemove: () => chatController.removeFile(),
                                ),
                              );
                            }

                            // 2. IMAGE PREVIEW
                            else if (isImage) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.inputField,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border.withOpacity(0.5),
                                  ),
                                ),
                                child: ImagePreviewInline(
                                  file: chatController.uploadMedia.value!,
                                  onRemove: () => chatController.removeFile(),
                                ),
                              );
                            }
                          }
                          // 3. NO MEDIA
                          return const SizedBox.shrink();
                        }),

                      //* Input row
                      Row(
                        children: [
                          //* Image upload button (hide in edit mode)
                          if (!_isEditMode)
                            IconButton(
                              icon: const Icon(Icons.image_outlined,
                                  color: AppColors.textDim, size: 24),
                              onPressed: () => chatController.pickImage(),
                            ),
                          if (!_isEditMode) const SizedBox(width: 4),

                          //* Microphone button (hide in edit mode)
                          if (!_isEditMode)
                            IconButton(
                              icon: const Icon(Icons.mic_outlined,
                                  color: AppColors.textDim, size: 24),
                              onPressed: () => chatController.pickAudio(),
                            ),
                          if (!_isEditMode) const SizedBox(width: 8),

                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.inputField,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _isEditMode
                                      ? AppColors.primary.withOpacity(0.5)
                                      : AppColors.border.withOpacity(0.5),
                                  width: _isEditMode ? 1.5 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: chatController.textCtrl,
                                onChanged: (val) =>
                                    chatController.onTypingChange(val),
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 15),
                                cursorColor: AppColors.accent,
                                maxLines: 4,
                                minLines: 1,
                                decoration: const InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle:
                                      TextStyle(color: AppColors.textDim),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.primary,
                                AppColors.accent
                              ]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isEditMode
                                    ? Icons.check_rounded
                                    : Icons.send_rounded,
                                color: AppColors.white,
                                size: 22,
                              ),
                              onPressed: _isEditMode
                                  ? () {
                                      _submitEdit(
                                          chatController.textCtrl.text.trim());
                                    }
                                  : () {
                                      chatController.sendMessage(
                                          _repliedTo ?? "",
                                          _repliedMessage ?? "");
                                      _replyModeCancel();
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),

          //* Floating Date Indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showDateIndicator ? 16 : -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  _currentDate,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(String isoTime) {
    try {
      DateTime dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (e) {
      return "";
    }
  }
}
