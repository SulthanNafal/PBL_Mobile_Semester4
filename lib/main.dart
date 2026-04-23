import 'package:flutter/material.dart';
import 'routes/app_routes.dart'; // Import file route kamu

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menghilangkan banner debug di pojok kanan atas
      debugShowCheckedModeBanner: false,

      title: 'Ursa Event',

      // Tema aplikasi (bisa disesuaikan nanti)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF24E4E)),
        useMaterial3: true,
      ),

      // 1. Tentukan halaman awal menggunakan nama route
      initialRoute: AppRoutes.login,

      // 2. Hubungkan dengan generator route yang sudah kita buat di app_routes.dart
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}