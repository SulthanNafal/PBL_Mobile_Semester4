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

  // =========================
  // NAVIGATOR KEY
  // =========================
  final GlobalKey<NavigatorState>
  navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {

    super.initState();

    // =========================
    // AUTH STATE LISTENER
    // =========================
    supabase.auth.onAuthStateChange.listen(

          (data) async {

        final event =
            data.event;

        // =========================
        // PASSWORD RECOVERY
        // =========================
        if (event ==
            AuthChangeEvent.passwordRecovery) {

          navigatorKey.currentState
              ?.pushNamed(
            AppRoutes.resetPassword,
          );
        }

        // =========================
        // LOGIN GOOGLE ONLY
        // =========================
        if (event ==
            AuthChangeEvent.signedIn) {

          final user =
              supabase.auth.currentUser;

          if (user == null) return;

          // =========================
          // CEK PROVIDER LOGIN
          // =========================
          final provider =
          user.appMetadata['provider'];

          // HANYA LOGIN GOOGLE
          if (provider != 'google') {
            return;
          }

          // =========================
          // CEK USER DATABASE
          // =========================
          dynamic userData =
          await supabase
              .schema('ursaevent')
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          // =========================
          // INSERT USER BARU GOOGLE
          // =========================
          if (userData == null) {

            await supabase
                .schema('ursaevent')
                .from('users')
                .insert({

              'id': user.id,

              'username':
              user.userMetadata?['name'] ??
                  user.email
                      ?.split('@')[0],

              'email':
              user.email,

              'password':
              '-',

              // DEFAULT ROLE
              'level':
              'user',

              'created_at':
              DateTime.now()
                  .toIso8601String(),
            });
          }

          // =========================
          // REDIRECT DASHBOARD USER
          // =========================
          navigatorKey.currentState
              ?.pushReplacementNamed(
            AppRoutes.user,
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

      // =========================
      // DEFAULT PAGE
      // =========================
      initialRoute:
      AppRoutes.login,

      // =========================
      // ROUTES
      // =========================
      onGenerateRoute:
      AppRoutes.generateRoute,
    );
  }
}