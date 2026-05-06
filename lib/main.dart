import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_routes.dart';

void main() async {

  // =========================
  // INIT FLUTTER
  // =========================
  WidgetsFlutterBinding.ensureInitialized();

  // =========================
  // INIT SUPABASE
  // =========================
  await Supabase.initialize(

    url:
    'https://bnhfjxxyxpwpwkmorlcg.supabase.co',

    anonKey:
    'sb_publishable_q5tTOYyPPiEXxmgNSekeiw_BzhOnQmk',
  );

  runApp(const MyApp());
}

// =========================
// GLOBAL SUPABASE CLIENT
// =========================
final supabase =
    Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState
    extends State<MyApp> {

  // navigator key
  final GlobalKey<NavigatorState>
  navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {

    super.initState();

    // =========================
    // LISTENER RESET PASSWORD
    // =========================
    supabase.auth.onAuthStateChange.listen(

          (data) {

        final event = data.event;

        // =========================
        // DETEKSI RECOVERY PASSWORD
        // =========================
        if (event ==
            AuthChangeEvent.passwordRecovery) {

          navigatorKey.currentState
              ?.pushNamed(
            AppRoutes.resetPassword,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner:
      false,

      title: 'Ursa Event',

      theme: ThemeData(

        colorScheme:
        ColorScheme.fromSeed(
          seedColor:
          const Color(0xFFF24E4E),
        ),

        useMaterial3: true,
      ),

      initialRoute:
      AppRoutes.login,

      onGenerateRoute:
      AppRoutes.generateRoute,
    );
  }
}