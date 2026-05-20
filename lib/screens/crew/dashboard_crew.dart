import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'crew_scan_page.dart';

class DashboardCrew extends StatelessWidget {
  const DashboardCrew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'Dashboard Crew',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        automaticallyImplyLeading: false,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false,
              );
            },
          ),
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Container(
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 12,
                  offset: const Offset(0,4),
                )
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFD32F2F,
                    ).withOpacity(.1),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 70,
                    color: Color(0xFFD32F2F),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Scan Tiket',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Scan QR tiket peserta untuk verifikasi masuk event',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CrewScanPage(),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFFD32F2F),

                      foregroundColor:
                      Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),

                    icon: const Icon(
                      Icons.camera_alt,
                    ),

                    label: const Text(
                      'Buka Scanner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}