import 'package:flutter/material.dart';
// Import halaman-halaman kamu
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';

class AppRoutes {
  // Nama-nama route didefinisikan sebagai konstanta statis
  // agar tidak ada typo saat memanggil Navigator.pushNamed
  static const String login = '/';
  static const String register = '/register';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    // Route untuk Login (Halaman Awal)
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

    // Route untuk Register
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );

    // Default route jika nama route tidak ditemukan
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