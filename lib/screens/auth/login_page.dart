import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/hash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // =========================
  // LOGIN FUNCTION
  // =========================
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showPopup(
        title: "Peringatan",
        message: "Email dan Password wajib diisi!",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Password di-hash agar sinkron dengan data di database
      String passwordHashed = HashCustom.encrypt(_passwordController.text.trim());

      final result = await authController.loginWithEmail(
        _emailController.text.trim(),
        passwordHashed,
      );

      if (result == "success") {
        if (!mounted) return;
        _showPopup(
          title: "Berhasil",
          message: "Login berhasil.\nSelamat datang kembali.",
        );
      } else {
        _showPopup(
          title: "Login Gagal",
          message: result ?? "Terjadi kesalahan saat login",
        );
      }
    } catch (e) {
      _showPopup(title: "Error", message: "Terjadi kesalahan sistem");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPopup({required String title, required String message, VoidCallback? onOK}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOK != null) onOK();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                // LOGO UTAMA
                Image.asset('assets/images/logo.png', height: 100, fit: BoxFit.contain),
                const SizedBox(height: 12),
                const Text("Selamat Datang di", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Text(
                  "URSAEVENT",
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),

                // INPUT EMAIL
                _buildTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // INPUT PASSWORD
                _buildTextField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),

                // LUPA PASSWORD & RESET (AREA TEKAN DIPERBAIKI)
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Lupa Password? ",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // TOMBOL LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // TOMBOL GOOGLE (Logo: google_logo.png)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => authController.loginWithGoogle(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_logo.png', height: 22),
                        const SizedBox(width: 12),
                        const Text(
                          "Login dengan Google",
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // LINK DAFTAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? ", style: TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                      child: const Text(
                        "Daftar",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
          onPressed: onToggle,
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}