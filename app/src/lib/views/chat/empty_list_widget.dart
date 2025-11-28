import 'package:chat_app/constants/colors.dart';
import 'package:flutter/material.dart';

Widget buildEmptyState(String name) {
  return Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Circle
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_chat_unread_rounded, // or Icons.waving_hand_rounded
              size: 48,
              color: AppColors.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Send a message to start a conversation with ${name}.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDim,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Optional: "Say Hi" Button shortcut
         
        ],
      ),
    ),
  );
}
