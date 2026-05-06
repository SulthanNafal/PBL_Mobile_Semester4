import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forget_page.dart';

class AppRoutes {
  // Nama-nama route sebagai konstanta agar tidak typo
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    switch (uri.path) {
    // 1. Route Login
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

    // 2. Route Register
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );

    // 3. Route Forget Password
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgetPage(),
        );

    // Default route
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }
}