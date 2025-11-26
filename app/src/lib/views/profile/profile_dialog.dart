import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/user_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class UserProfileDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onMessageTap;
  final VoidCallback? onBlockTap;
  final UserController? userController;

  const UserProfileDialog({
    super.key,
    required this.user,
    this.onMessageTap,
    this.onBlockTap,
    this.userController,
  });

  static void show({
    required UserModel user,
    VoidCallback? onMessageTap,
    VoidCallback? onBlockTap,
    UserController? userController,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: UserProfileDialog(
          user: user,
          onMessageTap: onMessageTap,
          onBlockTap: onBlockTap,
          userController: userController,
        ),
      ),
    );
  }

  //* Get display name (username or fallback to fullName)
  String get displayName => user.username ?? user.fullName ?? 'Unknown';

  //* Get first letter for avatar (from fullName if available, else username)
  String get avatarLetter {
    final name = user.fullName ?? user.username ?? '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  //* Check if profile URL is empty or placeholder
  bool get hasProfileImage =>
      user.profileURL != null &&
      user.profileURL!.isNotEmpty &&
      user.profileURL != "";

  //* Check if this is the current user's profile
  bool get isCurrentUser => userController?.user.value?.userId == user.userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //* Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textLight, size: 24),
                  onPressed: () => Get.back(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          //* Profile Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: userController != null && isCurrentUser
                          ? Obx(() {
                              final currentUser = userController!.user.value;
                              final isLoading = userController!.isLoading.value;

                              if (isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(AppColors.white),
                                  ),
                                );
                              }

                              final hasImage =
                                  currentUser?.profileURL != null &&
                                      currentUser!.profileURL!.isNotEmpty &&
                                      currentUser.profileURL != "";

                              return hasImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: CachedNetworkImage(
                                        imageUrl: currentUser.profileURL!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                AppColors.white),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Center(
                                          child: Text(
                                            avatarLetter,
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        avatarLetter,
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    );
                            })
                          : hasProfileImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: CachedNetworkImage(
                                    imageUrl: user.profileURL!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            AppColors.white),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Text(
                                        avatarLetter,
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    avatarLetter,
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                    ),

                    //* Edit button for current user
                    if (isCurrentUser && userController != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            await userController!.uploadProfilePictureUser();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),

                    //* Online indicator
                    if (user.isOnline == true)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Display Name (username or fullName)
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Online status or last seen
                if (user.isOnline == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                else if (user.lastSeen != null && user.lastSeen!.isNotEmpty)
                  Text(
                    'Last seen: ${_formatLastSeen(user.lastSeen!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontFamily: 'Poppins',
                    ),
                  ),

                const SizedBox(height: 24),

                //* Full Name section (if different from username)
                if (user.fullName != null &&
                    user.fullName!.isNotEmpty &&
                    user.username != null &&
                    user.fullName != user.username) ...[
                  _buildInfoCard(
                    icon: Icons.person_rounded,
                    label: 'Full Name',
                    value: user.fullName!,
                  ),
                  const SizedBox(height: 12),
                ],

                //* Username section (if available and different from fullName)
                if (user.username != null &&
                    user.username!.isNotEmpty &&
                    user.fullName != user.username) ...[
                  _buildInfoCard(
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: '@${user.username}',
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(String isoTime) {
    try {
      DateTime dt = DateTime.parse(isoTime).toLocal();
      DateTime now = DateTime.now();

      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'today at ${DateFormat('HH:mm').format(dt)}';
      }
      if (dt.day == now.day - 1 &&
          dt.month == now.month &&
          dt.year == now.year) {
        return 'yesterday at ${DateFormat('HH:mm').format(dt)}';
      }
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }
}
