import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRouter {
  // Định nghĩa tên các đường dẫn (Route Names)
  static const String login = '/login';
  static const String home = '/home';
  static const String register = '/register';

  // Bảng ánh xạ route
  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        home: (context) => const HomeScreen(),
        register: (context) => const RegisterScreen(),
      };
}