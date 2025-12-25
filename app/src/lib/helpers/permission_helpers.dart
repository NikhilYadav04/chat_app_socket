// app/src/lib/utils/permission_helper.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class PermissionHelper {
  
  //* Request camera and microphone permissions for calls
  static Future<bool> requestCallPermissions({required bool isVideo}) async {
    Map<Permission, PermissionStatus> statuses = {};

    if (isVideo) {
      statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
    } else {
      statuses = await [
        Permission.microphone,
      ].request();
    }

    bool allGranted = true;

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      Get.snackbar(
        'Permissions Required',
        'Please grant camera and microphone permissions to make calls',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return allGranted;
  }

  //* Check if permissions are already granted
  static Future<bool> hasCallPermissions({required bool isVideo}) async {
    if (isVideo) {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      return cameraStatus.isGranted && micStatus.isGranted;
    } else {
      final micStatus = await Permission.microphone.status;
      return micStatus.isGranted;
    }
  }

  //* Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
