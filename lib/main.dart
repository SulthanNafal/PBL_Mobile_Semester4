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

// GLOBAL SUPABASE
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // LISTENER AUTH
    supabase.auth.onAuthStateChange.listen(
          (data) async {

        final event = data.event;

        // ========================
        // PASSWORD RESET
        // ========================
        if (event ==
            AuthChangeEvent.passwordRecovery) {

          navigatorKey.currentState
              ?.pushNamed(
            AppRoutes.resetPassword,
          );

          return;
        }

        // ========================
        // LOGIN BERHASIL
        // ========================
        if (event ==
            AuthChangeEvent.signedIn) {

          final user =
              supabase.auth.currentUser;

          if (user == null) return;

          // ambil provider login
          final provider =
          user.appMetadata['provider'];

          dynamic userData =
          await supabase
              .schema('ursaevent')
              .from('users')
              .select()
              .eq(
            'id',
            user.id,
          )
              .maybeSingle();

          // ========================
          // JIKA LOGIN GOOGLE DAN
          // USER BELUM ADA
          // ========================
          if (provider == 'google' &&
              userData == null) {

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

              'password': '-',

              'level': 'user',

              'created_at':
              DateTime.now()
                  .toIso8601String(),
            });

            userData =
            await supabase
                .schema('ursaevent')
                .from('users')
                .select()
                .eq(
              'id',
              user.id,
            )
                .single();
          }

          // ========================
          // USER EMAIL BELUM ADA
          // ========================
          if (userData == null) return;

          // LEVEL USER
          final level =
              userData['level'] ?? 'user';

          String route =
              AppRoutes.user;

          switch(level){

            case 'superadmin':
              route =
                  AppRoutes.superadmin;
              break;

            case 'admin':
              route =
                  AppRoutes.admin;
              break;

            case 'crew':
              route =
                  AppRoutes.crew;
              break;

            case 'finance':
              route =
                  AppRoutes.finance;
              break;

            default:
              route =
                  AppRoutes.user;
          }

          navigatorKey.currentState
              ?.pushReplacementNamed(
            route,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner: false,

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