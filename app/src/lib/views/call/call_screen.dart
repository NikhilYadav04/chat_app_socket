import 'dart:async';

import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/call_controller.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();
    final args = Get.arguments as Map<String, dynamic>;
    final CallModel call = args['call'];
    final String receiverName = args['receiverName'];
    final String receiverProfileURL = args['receiverProfileURL'];

    Timer? _timer;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              //* 1. Background Layer (Remote Video or Audio UI)

              Obx(() {
                final activeCall = callController.currentCall.value;
                final isVideoCall = call.callType == CallType.video;

                if (isVideoCall) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: RTCVideoView(
                        callController.webrtcService.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  );
                } else {
                  return _buildAudioCallUI(
                      call, receiverProfileURL, receiverName);
                }
              }),

              //* 2. Local Video Preview
              Obx(() {
                final isVideoCall = call.callType == CallType.video;

                final isVideoEnabled =
                    callController.webrtcService.isVideoEnabled.value;
                final hasStream =
                    callController.webrtcService.localRenderer.srcObject !=
                        null;

                if (isVideoCall && isVideoEnabled && hasStream) {
                  return Positioned(
                    top: 50,
                    right: 20,
                    child: _buildLocalPreview(callController),
                  );
                } else if (isVideoCall && !isVideoEnabled) {
                  return Positioned(
                    top: 50,
                    right: 20,
                    child: _buildCameraOffOverlay(),
                  );
                }
                return const SizedBox.shrink();
              }),

              //* 3. Call Info (Timer)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: _buildCallInfo(call, callController),
              ),

              //* 4. Bottom Controls
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Obx(() {
                  return _buildCallControls(
                    callController,
                    call.callType == CallType.video,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview(CallController callController) {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
        color: AppColors.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: RTCVideoView(
          callController.webrtcService.localRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          mirror: true,
        ),
      ),
    );
  }

  Widget _buildCameraOffOverlay() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
        color: AppColors.surface,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: AppColors.textLight, size: 30),
            SizedBox(height: 4),
            Text('Camera Off',
                style: TextStyle(color: AppColors.textLight, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCallUI(
      CallModel call, String receiverProfileURL, String receiverName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withOpacity(0.3), AppColors.background],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: AppColors.primary,
            backgroundImage: (receiverProfileURL.isNotEmpty)
                ? NetworkImage(receiverProfileURL)
                : null,
            child: (receiverName.isNotEmpty)
                ? Text(receiverName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 48, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 32),
          Text(receiverName,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildCallInfo(CallModel call, CallController callController) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Obx(() {
          // Watching callDuration.value
          final status = callController.isRinging.value
              ? 'Ringing...'
              : _formatDuration(callController.callDuration.value);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!callController.isRinging.value)
                const Icon(Icons.fiber_manual_record,
                    color: Colors.green, size: 12),
              if (!callController.isRinging.value) const SizedBox(width: 8),
              Text(status,
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCallControls(CallController callController, bool isVideoCall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: callController.webrtcService.isAudioEnabled.value
              ? Icons.mic
              : Icons.mic_off,
          label: callController.webrtcService.isAudioEnabled.value
              ? 'Mute'
              : 'Unmute',
          onTap: () => callController.toggleAudio(),
          color: callController.webrtcService.isAudioEnabled.value
              ? AppColors.surface
              : Colors.red,
        ),
        if (isVideoCall)
          _buildControlButton(
            icon: callController.webrtcService.isVideoEnabled.value
                ? Icons.videocam
                : Icons.videocam_off,
            label: 'Video',
            onTap: () => callController.toggleVideo(),
            color: callController.webrtcService.isVideoEnabled.value
                ? AppColors.surface
                : Colors.red,
          ),
        _buildControlButton(
          icon: Icons.call_end,
          label: 'End',
          onTap: () => callController.endCall(isVideoCall),
          color: Colors.red,
          size: 70,
        ),
        if (isVideoCall)
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: callController.webrtcService.isVideoEnabled.value
                ? () => callController.switchCamera()
                : null,
            color: AppColors.surface,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required Color color,
    double size = 60,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: AppColors.text, fontSize: 12)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
