import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class DashboardFinance extends StatelessWidget {
  const DashboardFinance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ini dashboard finance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}