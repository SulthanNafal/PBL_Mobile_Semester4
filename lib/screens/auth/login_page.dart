import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = AuthController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // =========================
  // LOGIN FUNCTION
  // =========================
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showPopup(
        title: "Peringatan",
        message: "Username/Email dan Password wajib diisi!",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authController.loginWithEmail(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // LOGIN BERHASIL
      if (result != null && result is Map) {
        String level = result['level'] ?? 'user';
        String route = AppRoutes.user;

        switch (level) {
          case 'superadmin':
            route = AppRoutes.superadmin;
            break;
          case 'admin':
            route = AppRoutes.admin;
            break;
          case 'crew':
            route = AppRoutes.crew;
            break;
          case 'finance':
            route = AppRoutes.finance;
            break;
          case 'user':
            route = AppRoutes.user;
            break;
        }

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Berhasil"),
            content: Text("Login berhasil sebagai $level"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    route,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      // LOGIN GAGAL
      else {
        _showLoginFailedPopup();
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('ClientException')) {
        errorMessage = "Silahkan nyalakan internet / kuota anda";
      } else {
        errorMessage = "Terjadi kesalahan sistem";
      }

      _showPopup(
        title: "Login Gagal",
        message: errorMessage,
      );
    }

    // INI YANG PENTING
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // POPUP
  // =========================
  void _showPopup({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLoginFailedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Tidak Bisa Menemukan Akun",
        ),
        content: const Text(
          "Kami tidak bisa menemukan akun dengan username/email tersebut "
              "atau password salah.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // kosongkan password
              _passwordController.clear();
            },
            child: const Text("COBA LAGI"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.register,
              );
            },
            child: const Text("DAFTAR"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF24E4E),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // =========================
                // LOGO
                // =========================
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Selamat Datang di",
                  style: TextStyle(color: Colors.grey),
                ),

                const Text(
                  "URSAEVENT",
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                // =========================
                // USERNAME / EMAIL
                // =========================
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Username / Email",
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // PASSWORD
                // =========================
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                // =========================
                // FORGOT PASSWORD
                // =========================
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "Lupa Password?",
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.forgotPassword);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Reset",
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =========================
                // LOGIN BUTTON
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // GOOGLE LOGIN
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await authController.loginWithGoogle();
                      } catch (e) {
                        _showPopup(
                          title: "Google Login Gagal",
                          message: "Terjadi kesalahan saat login dengan Google",
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 22,
                          width: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text("Login dengan Google"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // REGISTER
                // =========================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text("Daftar"),
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