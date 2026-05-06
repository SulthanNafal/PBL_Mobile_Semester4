import 'package:flutter/material.dart';

import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forget_page.dart';
import '../screens/auth/reset_password_page.dart';

class AppRoutes {

  // =========================
  // ROUTE NAMES
  // =========================

  // LOGIN
  static const String login = '/';

  // REGISTER
  static const String register =
      '/register';

  // FORGOT PASSWORD
  static const String forgotPassword =
      '/forgot-password';

  // RESET PASSWORD
  static const String resetPassword =
      '/reset-password';

  // =========================
  // GENERATE ROUTE
  // =========================
  static Route<dynamic> generateRoute(
      RouteSettings settings,
      ) {

    final uri = Uri.parse(
      settings.name ?? '',
    );

    switch (uri.path) {

    // =========================
    // LOGIN PAGE
    // =========================
      case login:

        return MaterialPageRoute(
          builder: (_) =>
          const LoginPage(),
        );

    // =========================
    // REGISTER PAGE
    // =========================
      case register:

        return MaterialPageRoute(
          builder: (_) =>
          const RegisterPage(),
        );

    // =========================
    // FORGOT PASSWORD PAGE
    // =========================
      case forgotPassword:

        return MaterialPageRoute(
          builder: (_) =>
          const ForgetPage(),
        );

    // =========================
    // RESET PASSWORD PAGE
    // =========================
      case resetPassword:

        return MaterialPageRoute(
          builder: (_) =>
          const ResetPasswordPage(),
        );

    // =========================
    // DEFAULT ERROR PAGE
    // =========================
      default:

        return MaterialPageRoute(

          builder: (_) => Scaffold(

            body: Center(

              child: Text(
                'Halaman tidak ditemukan: ${settings.name}',
              ),
            ),
          ),
        );
    }
  }
}