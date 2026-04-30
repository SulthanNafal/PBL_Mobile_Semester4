import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'routes/app_routes.dart';

void main() async {
  // 1. Pastikan binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Supabase (Cuma SEKALI seumur hidup aplikasi)
  await Supabase.initialize(
    // GANTI URL ini dengan Project URL (bukan URL Dashboard)
    url: 'https://bnhfjxxyxpwpwkmorlcg.supabase.co',
    anonKey: 'sb_publishable_q5tTOYyPPiEXxmgNSekeiw_BzhOnQmk',
  );

  runApp(const MyApp());
}

// 3. Buat variabel global supaya gampang dipanggil di file mana pun
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ursa Event',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF24E4E)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}