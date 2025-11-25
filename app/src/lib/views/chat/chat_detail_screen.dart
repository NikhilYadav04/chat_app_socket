import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_controller.dart';
import '../../models/message_model.dart';
import '../../constants/colors.dart';

class ChatDetailScreen extends StatelessWidget {
  ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.put(ChatController());

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
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  chatController.partnerName[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white),
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
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.separated(
                reverse: true,
                controller: chatController.scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        onChanged: (val) => chatController.onTypingChange(val),
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
                    size: 16, // Slightly larger to see the double ticks clearly
                    color: msg.status == 'read'
                        ? const Color(0xFF00E5FF) // Bright Cyan for Read
                        : AppColors.white
                            .withOpacity(0.6), // Dim White for Sent/Delivered
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
        ? Icons.done_all_rounded // Double check
        : status == 'sent'
            ? Icons.check_rounded // Single check
            : Icons.access_time_rounded; // Clock
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
