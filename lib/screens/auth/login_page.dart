import 'package:flutter/material.dart';
import '../../routes/app_routes.dart'; // Import routes untuk navigasi

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background merah sesuai gambar referensi
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
                // Logo diambil dari folder assets/images/
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  fit: MainAxisSize.min == MainAxisSize.min ? BoxFit.contain : BoxFit.fill,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Selamat Datang di",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
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

                // Input Email
                TextField(
                  decoration: InputDecoration(
                    hintText: "Email",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Input Password
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: const Icon(Icons.visibility_off_outlined, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Lupa Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Tambahkan navigasi lupa password di sini jika perlu
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Lupa Password? ",
                        style: TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(
                            text: "Forgot",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tombol Login Utama
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logika Login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text("atau", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // Tombol Login Google
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.network(
                      'https://tinyurl.com/google-logo-png-transparent', // Fallback link icon Google
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30),
                    ),
                    label: const Text(
                      "Login dengan Google",
                      style: TextStyle(color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Link ke Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? ", style: TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () {
                        // Navigasi menggunakan sistem Named Routes
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text(
                        "Daftar",
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
}