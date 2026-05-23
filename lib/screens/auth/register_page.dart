import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final AuthController authC = AuthController();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // ==========================
  // 🚀 HANDLE REGISTER
  // ==========================
  Future<void> _handleRegister() async {

    // VALIDASI KOSONG
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {

      _showPopup(
        title: "Peringatan",
        message: "Semua field wajib diisi!",
      );
      return;
    }

    // VALIDASI PASSWORD
    if (_passwordController.text != _confirmController.text) {

      _showPopup(
        title: "Peringatan",
        message: "Password tidak cocok!",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {

      final result = await authC.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // ==========================
// SUCCESS REGISTER / TAMBAH PASSWORD
// ==========================
      if (
      result == "success" ||
          result == "Password berhasil ditambahkan"
      ) {

        if (!mounted) return;

        String message;

        // tambah password akun Google
        if (result ==
            "Password berhasil ditambahkan") {

          message =
          "Password berhasil ditambahkan.\n"
              "Sekarang Anda dapat login menggunakan Google atau Email.";

        } else {

          // register akun baru
          message =
          "Registrasi berhasil.\n"
              "Silakan cek email untuk verifikasi akun.";
        }

        showDialog(

          context: context,

          barrierDismissible: false,

          builder: (_) =>
              AlertDialog(

                title:
                const Text(
                    "Berhasil"
                ),

                content:
                Text(
                    message
                ),

                actions: [

                  TextButton(

                    onPressed: () {

                      Navigator.pop(
                          context);

                      Navigator.pop(
                          context);
                    },

                    child:
                    const Text(
                        "OK"
                    ),
                  ),
                ],
              ),
        );

      } else {

        // ==========================
        // ERROR POPUP
        // ==========================

        _showPopup(

          title:
          "Register Gagal",

          message:
          result ??
              "Terjadi kesalahan",
        );
      }

    } catch (e) {

      _showPopup(
        title: "Error",
        message: e.toString(),
      );

    } finally {

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================
  // 🔥 POPUP FUNCTION
  // ==========================
  void _showPopup({
    required String title,
    required String message,
  }) {

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF24E4E),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),

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

                // ==========================
                // LOGO
                // ==========================
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Daftar Akun",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

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

                // ==========================
                // USERNAME
                // ==========================
                _buildTextField(
                  controller: _usernameController,
                  hint: "Username",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 16),

                // ==========================
                // EMAIL
                // ==========================
                _buildTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // ==========================
                // PASSWORD
                // ==========================
                _buildTextField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,

                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ==========================
                // CONFIRM PASSWORD
                // ==========================
                _buildTextField(
                  controller: _confirmController,
                  hint: "Ulangi Password",
                  icon: Icons.lock_reset,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,

                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // ==========================
                // BUTTON REGISTER
                // ==========================
                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(

                    onPressed:
                    _isLoading ? null : _handleRegister,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFD32F2F),

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
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
                      "Daftar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================
                // LOGIN
                // ==========================
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    const Text(
                      "Sudah punya akun? ",
                      style: TextStyle(fontSize: 13),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),

                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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

  // ==========================
  // 🔧 TEXT FIELD BUILDER
  // ==========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,

    bool isPassword = false,
    bool obscureText = false,

    VoidCallback? onToggle,

    TextInputType keyboardType =
        TextInputType.text,
  }) {

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,

      decoration: InputDecoration(

        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: Colors.grey,
          size: 22,
        ),

        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,

            color: Colors.grey,
            size: 20,
          ),

          onPressed: onToggle,
        )
            : null,

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),

          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}