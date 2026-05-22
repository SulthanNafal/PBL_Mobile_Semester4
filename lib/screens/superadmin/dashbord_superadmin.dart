import 'package:flutter/material.dart';

import 'superadmin_dashboard_page.dart';
import 'superadmin_event_page.dart';
import 'superadmin_transaksi_page.dart';
import 'superadmin_scan_page.dart';
import 'superadmin_profile_page.dart';

class DashbordSuperadmin extends StatefulWidget {
  const DashbordSuperadmin({super.key});

  @override
  State<DashbordSuperadmin> createState() => _DashbordSuperadminState();
}

class _DashbordSuperadminState extends State<DashbordSuperadmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SuperadminDashboardPage(),
    const SuperadminEventPage(),
    const SuperadminTransaksiPage(),
    const SuperadminScanPage(),
    const SuperadminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6A1B9A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Event',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}