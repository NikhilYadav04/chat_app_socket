import 'package:chat_app/constants/colors.dart';
import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/views/auth/register_screen.dart';
import 'package:chat_app/views/auth/text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.text,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      size: 40,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: userCtrl,
                  label: 'Username',
                  hint: 'Enter your username',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                Obx(() => CustomTextField(
                      controller: passCtrl,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: authController.isPasswordHidden.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          authController.isPasswordHidden.value
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () {
                          authController.isPasswordHidden.value =
                              !authController.isPasswordHidden.value;
                        },
                      ),
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authController.isLoading.value
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                authController.login(
                                  userCtrl.text.trim(),
                                  passCtrl.text.trim(),
                                );
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
                        child: authController.isLoading.value
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(() => RegisterScreen()),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
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
        ),
      ),
    );
  }
}
