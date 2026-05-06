import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = AuthController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // =========================
  // LOGIN FUNCTION
  // =========================
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage("Email dan Password wajib diisi!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await authController.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (res.user != null) {
        _showMessage("Login berhasil");

        // pindah halaman setelah login
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
        );
      }
    } catch (e) {
      _showMessage("Login gagal: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================
  // SNACKBAR
  // =========================
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
                  style: TextStyle(
                    color: Colors.grey,
                  ),
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
                // EMAIL
                // =========================
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    hintText: "Email",

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                          !_obscurePassword;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // =========================
                // FORGOT PASSWORD
                // =========================
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                      );
                    },

                    child: const Text(
                      "Lupa Password?",
                    ),
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
                    onPressed:
                    _isLoading ? null : _handleLogin,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFD32F2F),
                    ),

                    child: _isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
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
                        await authController
                            .loginWithGoogle();

                        _showMessage(
                          "Login Google berhasil",
                        );
                      } catch (e) {
                        _showMessage(
                          "Google login gagal: $e",
                        );
                      }
                    },

                    child: const Text(
                      "Login dengan Google",
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // REGISTER
                // =========================
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Belum punya akun?",
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.register,
                        );
                      },

                      child: const Text(
                        "Daftar",
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