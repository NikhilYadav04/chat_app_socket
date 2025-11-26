import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

Widget buildUserList(HomeController homeController) {
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
                icon:
                    const Icon(Icons.close_rounded, color: AppColors.textLight),
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
                    final hasProfileImage = user.profileURL != null &&
                        user.profileURL!.isNotEmpty &&
                        user.profileURL != "";
                    final avatarLetter = user.username?[0].toUpperCase() ?? "?";

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
                            'partnerName': user.username,
                            'partnerURL': user.profileURL
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
                                child: hasProfileImage
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: user.profileURL!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppColors.white),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Center(
                                            child: Text(
                                              avatarLetter,
                                              style: const TextStyle(
                                                fontSize: 18,
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
