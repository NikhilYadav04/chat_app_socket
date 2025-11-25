import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/views/auth/login-screen.dart';
import 'package:chat_app/views/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 60,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ChatConnect',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Simple, secure messaging\nConnect with anyone, anywhere',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeature(Icons.lock_outline, 'Secure'),
                  _buildFeature(Icons.speed, 'Fast'),
                  _buildFeature(Icons.favorite_outline, 'Simple'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Get.to(() => RegisterScreen());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
