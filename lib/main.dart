import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bnhfjxxyxpwpwkmorlcg.supabase.co',
    anonKey: 'sb_publishable_q5tTOYyPPiEXxmgNSekeiw_BzhOnQmk',
  );

  runApp(const MyApp());
}

// =========================
// GLOBAL SUPABASE
// =========================
final supabase =
    Supabase.instance.client;

// FLAG LOGIN GOOGLE
bool isGoogleAuth = false;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState
    extends State<MyApp> {

  final GlobalKey<NavigatorState>
  navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // =========================
    // LISTENER AUTH
    // =========================
    supabase.auth
        .onAuthStateChange
        .listen(

          (data) async {

        final event =
            data.event;

        // =========================
        // PASSWORD RESET
        // =========================
        if (event ==
            AuthChangeEvent
                .passwordRecovery) {

          navigatorKey.currentState
              ?.pushNamed(
            AppRoutes
                .resetPassword,
          );

          return;
        }

        // =========================
        // LOGIN BERHASIL
        // =========================
        if (event ==
            AuthChangeEvent
                .signedIn) {

          final user =
              supabase.auth
                  .currentUser;

          if (user == null) return;

          // =========================
          // LOGIN GOOGLE
          // =========================
          if (isGoogleAuth) {

            // reset flag
            isGoogleAuth = false;

            navigatorKey
                .currentState
                ?.pushReplacementNamed(
              AppRoutes.user,
            );

            return;
          }

          // ==========================
          // LOGIN EMAIL BIASA
          // ==========================

          await supabase
              .schema('ursaevent')
              .from('users')
              .select()
              .eq(
            'email',
            user.email!,
          )
              .single();

        // jangan redirect otomatis
          return;
        }
      },
    );
  }

  @override
  Widget build(
      BuildContext context) {

    return MaterialApp(

      navigatorKey:
      navigatorKey,

      debugShowCheckedModeBanner:
      false,

      title:
      'Ursa Event',

      theme:
      ThemeData(

        colorScheme:
        ColorScheme
            .fromSeed(

          seedColor:
          const Color(
            0xFFF24E4E,
          ),
        ),

        useMaterial3:
        true,
      ),

      initialRoute:
      AppRoutes.login,

      onGenerateRoute:
      AppRoutes.generateRoute,
    );
  }
}