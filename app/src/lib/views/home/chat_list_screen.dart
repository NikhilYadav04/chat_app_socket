import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../constants/colors.dart';

class ChatListScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final AuthController authController = Get.find<AuthController>();

  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (homeController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (homeController.chatRooms.isEmpty) return _buildEmptyState();

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: homeController.chatRooms.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildChatItem(homeController.chatRooms[index]),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            homeController.fetchAllUsers();
            Get.bottomSheet(_buildUserList(), isScrollControlled: true);
          },
          child:
              const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.5,
                ),
              ),
              Obx(() => Text(
                    '${homeController.chatRooms.length} active chats',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontFamily: 'Poppins',
                    ),
                  )),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textLight),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding:
                  const EdgeInsets.only(left: 4), // Visual center correction
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(room) {
    final unread = (room.unreadCount ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unread
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          if (unread)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            homeController.markChatAsReadOnUI(room.userId!);
            Get.toNamed('/chat', arguments: {
              'partnerId': room.userId,
              'partnerName': room.username
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      room.username?[0].toUpperCase() ?? "?",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            room.username ?? "Unknown",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.text,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            _formatTime(room.latestMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.normal,
                              color: unread
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!unread && room.latestMessageStatus != null) ...[
                            Icon(
                              _getStatusIcon(room.latestMessageStatus),
                              size: 14,
                              color: room.latestMessageStatus == 'read'
                                  ? AppColors.accent
                                  : AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              room.latestMessage ?? "Sent a photo",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: unread
                                    ? AppColors.text
                                    : AppColors.textLight,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                "${room.unreadCount}",
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: AppColors.textLight.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to start chatting',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textLight),
                  onPressed: () => Get.back(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: Obx(() => homeController.allUsers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: homeController.allUsers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      var user = homeController.allUsers[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Get.back();
                            Get.toNamed('/chat', arguments: {
                              'partnerId': user.userId,
                              'partnerName': user.username
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.username?[0].toUpperCase() ?? "?",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  user.username ?? "",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.textDim,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return "";
    DateTime dt = DateTime.parse(time).toLocal();
    DateTime now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('HH:mm').format(dt);
    }
    if (dt.day == now.day - 1 && dt.month == now.month && dt.year == now.year) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd').format(dt);
  }

  IconData _getStatusIcon(String? status) {
    return status == 'read' || status == 'delivered'
        ? Icons.done_all_rounded
        : status == 'sent'
            ? Icons.check_rounded
            : Icons.access_time_rounded;
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 32, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        authController.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Logout',
                          style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
