import 'package:flutter/material.dart';

// =========================
// AUTH PAGES
// =========================
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/forget_page.dart';
import '../screens/auth/reset_password_page.dart';

// =========================
// DASHBOARD PAGES
// =========================
import '../screens/admin/dashboard_admin.dart';
import '../screens/crew/dashboard_crew.dart';
import '../screens/finance/dashboard_finance.dart';
import '../screens/superadmin/dashbord_superadmin.dart';
import '../screens/user/dashboard_user.dart';

class AppRoutes {

  // =========================
  // AUTH ROUTES
  // =========================
  static const String login =
      '/';

  static const String register =
      '/register';

  static const String forgotPassword =
      '/forgot-password';

  static const String resetPassword =
      '/reset-password';

  // =========================
  // DASHBOARD ROUTES
  // =========================
  static const String superadmin =
      '/superadmin';

  static const String admin =
      '/admin';

  static const String crew =
      '/crew';

  static const String finance =
      '/finance';

  static const String user =
      '/user';

  // =========================
  // GENERATE ROUTE
  // =========================
  static Route<dynamic> generateRoute(
      RouteSettings settings,
      ) {

    final uri = Uri.parse(
      settings.name ?? '',
    );

    switch (uri.path) {

    // =========================
    // LOGIN PAGE
    // =========================
      case login:

        return MaterialPageRoute(
          builder: (_) =>
          const LoginPage(),
        );

    // =========================
    // REGISTER PAGE
    // =========================
      case register:

        return MaterialPageRoute(
          builder: (_) =>
          const RegisterPage(),
        );

    // =========================
    // FORGOT PASSWORD PAGE
    // =========================
      case forgotPassword:

        return MaterialPageRoute(
          builder: (_) =>
          const ForgetPage(),
        );

    // =========================
    // RESET PASSWORD PAGE
    // =========================
      case resetPassword:

        return MaterialPageRoute(
          builder: (_) =>
          const ResetPasswordPage(),
        );

    // =========================
    // SUPERADMIN DASHBOARD
    // =========================
      case superadmin:

        return MaterialPageRoute(
          builder: (_) =>
          const DashbordSuperadmin(),
        );

    // =========================
    // ADMIN DASHBOARD
    // =========================
      case admin:

        return MaterialPageRoute(
          builder: (_) =>
          const DashboardAdmin(),
        );

    // =========================
    // CREW DASHBOARD
    // =========================
      case crew:

        return MaterialPageRoute(
          builder: (_) =>
          const DashboardCrew(),
        );

    // =========================
    // FINANCE DASHBOARD
    // =========================
      case finance:

        return MaterialPageRoute(
          builder: (_) =>
          const DashboardFinance(),
        );

    // =========================
    // USER DASHBOARD
    // =========================
      case user:

        return MaterialPageRoute(
          builder: (_) =>
          const DashboardUser(),
        );

    // =========================
    // DEFAULT ERROR PAGE
    // =========================
      default:

        return MaterialPageRoute(

          builder: (_) => Scaffold(

            body: Center(

              child: Text(
                'Halaman tidak ditemukan: ${settings.name}',
              ),
            ),
          ),
        );
    }
  }
}