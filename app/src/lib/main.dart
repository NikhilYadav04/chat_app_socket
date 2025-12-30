import 'package:chat_app/bindings/initial_binding.dart';
import 'package:chat_app/views/auth/login-screen.dart';
import 'package:chat_app/views/call/call_history_screen.dart';
import 'package:chat_app/views/call/call_screen.dart';
import 'package:chat_app/views/call/incoming_call_screen.dart';
import 'package:chat_app/views/landing/landing_screen.dart';
import 'package:chat_app/views/landing/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:get/get.dart';
import 'views/home/chat_list_screen.dart';
import 'views/chat/chat_detail_screen.dart';

void main() {
  runApp(const MyApp());

  SystemUiOverlayStyle(
      statusBarColor: Colors.white, statusBarBrightness: Brightness.light);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Realtime Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Now this works because we imported 'bindings/initial_binding.dart'
      initialBinding: InitialBinding(),

      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => SplashScreen()),
        GetPage(name: '/landing', page: () => LandingScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/home', page: () => ChatListScreen()),
        GetPage(name: '/chat', page: () => ChatDetailScreen()),
        GetPage(
          name: '/call',
          page: () => const CallScreen(),
        ),
        GetPage(
          name: '/incoming-call',
          page: () => const IncomingCallScreen(),
        ),
        GetPage(name: '/history', page: () => CallHistoryScreen())
      ],
    );
  }
}
