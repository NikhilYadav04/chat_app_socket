// app/src/lib/views/call/incoming_call_screen.dart

import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/call_controller.dart';
import 'package:chat_app/models/call_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();
    final args = Get.arguments as Map<String, dynamic>;
    final CallModel call = args['call'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.background,
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),

              //* Call type indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      call.callType == CallType.video
                          ? Icons.videocam
                          : Icons.phone,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      call.callType == CallType.video
                          ? 'Video Call'
                          : 'Voice Call',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              //* Caller profile picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: AppColors.primary,
                  backgroundImage: call.callerProfileURL != null &&
                          call.callerProfileURL!.isNotEmpty
                      ? NetworkImage(call.callerProfileURL!)
                      : null,
                  child: call.callerProfileURL == null ||
                          call.callerProfileURL!.isEmpty
                      ? Text(
                          call.callerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              //* Caller name
              Text(
                call.callerName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 8),

              //* Caller full name
              if (call.callerFullName != null &&
                  call.callerFullName!.isNotEmpty)
                Text(
                  call.callerFullName!,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),

              const SizedBox(height: 16),

              //* Ringing indicator
              Obx(() {
                if (callController.isRinging.value) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRingingDot(0),
                      const SizedBox(width: 8),
                      _buildRingingDot(1),
                      const SizedBox(width: 8),
                      _buildRingingDot(2),
                      const SizedBox(width: 12),
                      const Text(
                        'Incoming call...',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              const Spacer(),

              //* Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //* Reject button
                    _buildActionButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: () => callController.rejectCall(
                          isVideo: call.callType == CallType.video),
                    ),

                    //* Accept button
                    _buildActionButton(
                      icon: Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: () => callController.acceptCall(
                          receiverName: call.callerName,
                          receiverProfileURL: call.callerProfileURL ?? ""),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(value),
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
