import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // =========================
  // SEND RESET PASSWORD EMAIL
  // =========================
  Future<void> _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      _showPopup(
        title: "Peringatan",
        message: "Masukkan email terlebih dahulu",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // =========================
      // CEK EMAIL ADA / TIDAK
      // =========================
      final userData = await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (userData == null) {
        _showPopup(
          title: "Email Tidak Ditemukan",
          message: "Email tidak terdaftar pada sistem",
        );
        return;
      }

      // =========================
      // KIRIM EMAIL RESET PASSWORD
      // =========================
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'com.ursaevent.app://reset-password/',
      );

      // =========================
      // SUCCESS POPUP
      // =========================
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Berhasil"),
          content: const Text(
            "Link reset password berhasil dikirim.\nSilakan cek email Anda.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      _showPopup(
        title: "Reset Password Gagal",
        message: e.message,
      );
    } catch (e) {
      _showPopup(
        title: "Error",
        message: "Terjadi kesalahan sistem",
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
  // POPUP FUNCTION
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF24E4E),

      // =========================
      // APPBAR — panah kiri dihapus
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // hapus tombol back
      ),

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
                // ICON
                // =========================
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: Color(0xFFD32F2F),
                ),

                const SizedBox(height: 16),

                // =========================
                // TITLE
                // =========================
                const Text(
                  "Lupa Password?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC62828),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Masukkan email akun kamu untuk menerima link reset password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                // =========================
                // INPUT EMAIL
                // =========================
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email Anda",
                    prefixIcon: const Icon(
                      Icons.email_outlined,
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

                const SizedBox(height: 24),

                // =========================
                // BUTTON KIRIM
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
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
                      "Kirim Link Reset",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // BACK LOGIN
                // =========================
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "← Kembali ke Halaman Login",
                    style: TextStyle(color: Colors.grey),
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