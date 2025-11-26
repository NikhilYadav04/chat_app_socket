import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_controller.dart';
import '../../models/message_model.dart';
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
                  return ListView.separated(
                    reverse: true,
                    controller: chatController.scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    separatorBuilder: (ctx, i) => const SizedBox(height: 2),
                    itemCount: chatController.messages.length +
                        (chatController.hasMoreMessages.value ? 1 : 0),
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
                      return _buildMessageBubble(msg);
                    },
                  );
                }),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputField,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: TextField(
                            controller: chatController.textCtrl,
                            onChanged: (val) =>
                                chatController.onTypingChange(val),
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 15),
                            cursorColor: AppColors.accent,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: AppColors.textDim),
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
                          gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: AppColors.white, size: 22),
                          onPressed: () => chatController.sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Date Indicator
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

  Widget _buildMessageBubble(MessageModel msg) {
    final round = BorderRadius.circular(20).topLeft;
    final sharp = BorderRadius.circular(4).topLeft;

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: msg.isMine ? round : sharp,
            bottomRight: msg.isMine ? sharp : round,
          ),
          gradient: msg.isMine
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: msg.isMine ? null : AppColors.receivedMsgBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.message ?? "",
              style: TextStyle(
                fontSize: 15,
                color: msg.isMine ? AppColors.white : AppColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(msg.createdAt!.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: msg.isMine
                        ? AppColors.white.withOpacity(0.7)
                        : AppColors.textLight,
                  ),
                ),
                if (msg.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(msg.status),
                    size: 16,
                    color: msg.status == 'read'
                        ? const Color(0xFF00E5FF)
                        : AppColors.white.withOpacity(0.6),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    return status == 'read' || status == 'delivered'
        ? Icons.done_all_rounded
        : status == 'sent'
            ? Icons.check_rounded
            : Icons.access_time_rounded;
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
