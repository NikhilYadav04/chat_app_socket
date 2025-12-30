import 'package:chat_app/controllers/user_controller.dart';
import 'package:chat_app/views/home/user_list_dialog.dart';
import 'package:chat_app/views/profile/profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());
  final AuthController authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();

  Future<void> _refresh() async {
    homeController.fetchChatRooms(forceRefresh: true);
  }

  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          displacement: 40.0,
          edgeOffset: 0.0,
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
          onRefresh: _refresh,
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
                  if (homeController.chatRooms.isEmpty)
                    return _buildEmptyState();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
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
            Get.bottomSheet(buildUserList(homeController),
                isScrollControlled: true);
          },
          child:
              const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final UserController userController = Get.find<UserController>();
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
          Row(
            children: [
              // Profile button
              Obx(() {
                if (userController.user.value != null) {
                  final user = userController.user.value!;
                  final avatarLetter =
                      (user.fullName ?? user.username ?? '?')[0].toUpperCase();

                  return GestureDetector(
                    onTap: () {
                      UserProfileDialog.show(
                        user: user,
                        onMessageTap: null,
                        onBlockTap: null,
                        userController: userController,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Obx(() {
                        final currentUser = userController.user.value;
                        var logger = Logger();

                        if (currentUser != null &&
                            currentUser.profileURL != null &&
                            currentUser.profileURL!.isNotEmpty) {
                          logger.d(currentUser!.profileURL);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: currentUser.profileURL!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(AppColors.primary),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  avatarLetter,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            avatarLetter,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(width: 12),
              //* Logout button
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.textLight),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.only(left: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showLogoutDialog(),
              ),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                icon:
                    Center(child: Icon(Icons.history, color: AppColors.white)),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.only(left: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Get.toNamed(
                    '/history',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(room) {
    final unread = (room.unreadCount ?? 0) > 0;
    final hasProfileImage =
        room.profileURL != null && room.profileURL!.isNotEmpty;

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
            // var logger = Logger();
            // logger.d(room);
            Get.toNamed('/chat', arguments: {
              'partnerId': room.userId,
              'partnerName': room.fullName ?? room.username,
              'partnerURL': room.profileURL ?? ""
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: hasProfileImage
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: hasProfileImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: room.profileURL!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (room.fullName ?? room.username)?[0]
                                          .toUpperCase() ??
                                      "?",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (room.fullName ?? room.username)?[0]
                                          .toUpperCase() ??
                                      "?",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            (room.fullName ?? room.username)?[0]
                                    .toUpperCase() ??
                                "?",
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
                          Expanded(
                            child: Text(
                              room.fullName ?? room.username ?? "Unknown",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.text,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
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
