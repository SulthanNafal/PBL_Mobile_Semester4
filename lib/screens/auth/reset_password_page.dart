import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState
    extends State<ResetPasswordPage> {

  final AuthController authController =
  AuthController();

  final _passwordController =
  TextEditingController();

  final _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  // =========================
  // RESET PASSWORD
  // =========================
  Future<void> _handleResetPassword() async {

    // =========================
    // VALIDASI PASSWORD KOSONG
    // =========================
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController
            .text
            .isEmpty) {

      _showMsg(
        "Password wajib diisi",
      );

      return;
    }

    // =========================
    // VALIDASI MINIMAL PASSWORD
    // =========================
    if (_passwordController.text.length < 6) {

      _showMsg(
        "Password minimal 6 karakter",
      );

      return;
    }

    // =========================
    // VALIDASI KONFIRMASI PASSWORD
    // =========================
    if (_passwordController.text !=
        _confirmPasswordController.text) {

      _showMsg(
        "Konfirmasi password tidak sama",
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

      // =========================
      // UPDATE PASSWORD
      // =========================
      final result =
      await authController.updatePassword(

        newPassword:
        _passwordController.text.trim(),
      );

      // =========================
      // BERHASIL
      // =========================
      if (result == "success") {

        _showMsg(
          "Password berhasil diubah",
        );

        // kembali ke login
        Future.delayed(
          const Duration(seconds: 2),
              () {

            if (mounted) {

              Navigator.pushNamedAndRemoveUntil(

                context,

                AppRoutes.login,

                    (route) => false,
              );
            }
          },
        );

      } else {

        _showMsg(
          result ??
              "Gagal reset password",
        );
      }

    } catch (e) {

      _showMsg(
        "Terjadi kesalahan sistem",
      );

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
  void _showMsg(String msg) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(msg),
      ),
    );
  }

  @override
  void dispose() {

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF24E4E),

      // =========================
      // APPBAR
      // =========================
      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Center(

        child: SingleChildScrollView(

          child: Container(

            margin:
            const EdgeInsets.symmetric(
              horizontal: 24,
            ),

            padding:
            const EdgeInsets.all(24),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius:
              BorderRadius.circular(20),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                // =========================
                // ICON
                // =========================
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: Color(0xFFD32F2F),
                ),

                const SizedBox(height: 20),

                // =========================
                // TITLE
                // =========================
                const Text(

                  "Reset Password",

                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xFFC62828),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(

                  "Masukkan password baru untuk akun Anda.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // =========================
                // PASSWORD BARU
                // =========================
                TextField(

                  controller:
                  _passwordController,

                  obscureText:
                  _obscurePassword,

                  decoration: InputDecoration(

                    hintText:
                    "Password Baru",

                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon:
                    IconButton(

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

                    border:
                    OutlineInputBorder(

                      borderRadius:
                      BorderRadius.circular(
                          10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // KONFIRMASI PASSWORD
                // =========================
                TextField(

                  controller:
                  _confirmPasswordController,

                  obscureText:
                  _obscureConfirmPassword,

                  decoration: InputDecoration(

                    hintText:
                    "Konfirmasi Password",

                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon:
                    IconButton(

                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {

                        setState(() {

                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),

                    border:
                    OutlineInputBorder(

                      borderRadius:
                      BorderRadius.circular(
                          10),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =========================
                // BUTTON RESET
                // =========================
                SizedBox(

                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(

                    onPressed:
                    _isLoading
                        ? null
                        : _handleResetPassword,

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      const Color(
                          0xFFD32F2F),

                      shape:
                      RoundedRectangleBorder(

                        borderRadius:
                        BorderRadius.circular(
                            10),
                      ),
                    ),

                    child:
                    _isLoading
                        ? const SizedBox(

                      width: 20,
                      height: 20,

                      child:
                      CircularProgressIndicator(

                        color:
                        Colors.white,

                        strokeWidth: 2,
                      ),
                    )
                        : const Text(

                      "Reset Password",

                      style: TextStyle(
                        color:
                        Colors.white,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}