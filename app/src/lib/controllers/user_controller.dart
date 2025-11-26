import 'dart:io';

import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class UserController extends GetxController {
  //* variables
  RxBool isLoading = false.obs;
  Rx<UserModel?> user = Rx<UserModel?>(null);

  //* services
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();

    //* get user data
    var logger = Logger();
    logger.d("Inside user controller");
    fetchUserData();
  }

  //* functions
  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;

      final response = await _apiService.getUserProfileData();

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch user data. Status: ${response.statusCode}');
      }

      final userMap = response.data?["user"] as Map<String, dynamic>?;

      if (userMap == null) {
        throw Exception('Invalid user data structure in response.');
      }

      UserModel userData = UserModel.fromJson(userMap);

      user.value = userData;

      // var logger = Logger();
      // logger.d(user.value!.fullName);
      // logger.d(user.value!.userId);
      // logger.d(user.value!.profileURL);
    } catch (e) {
      print('Error fetching user data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> upload({required File file}) async {
    try {
      final response = await _apiService.uploadProfilePicture(file);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to upload profile picture. Status: ${response.statusCode}');
      }

      Map<String, dynamic> responseMap = response.data as Map<String, dynamic>;

      user.value = user.value!.copyWith(profileURL: responseMap["url"]);

      return "success";
    } catch (e) {
      print('Error uploading photo : ${e.toString()}');

      return 'Error uploading photo : ${e.toString()}';
    } finally {}
  }

  Future<void> uploadProfilePictureUser() async {
    try {
      isLoading.value = true;

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

      //* Upload the image
      String message = await upload(file: File(pickedFile.path));

      //* Show success message
      if (message == "success") {
        Get.snackbar(
          'Success',
          'Profile picture updated successfully',
          backgroundColor: AppColors.accent,
          colorText: AppColors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error picking image: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to update profile picture',
        backgroundColor: Colors.red,
        colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

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

  void clear() {
    user.value = Rx<UserModel?>(null).value;
    isLoading.value = false;
  }
}
