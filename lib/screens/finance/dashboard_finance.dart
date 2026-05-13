import 'package:flutter/material.dart';
import 'finance_transaksi_page.dart';
import 'finance_profile_page.dart';

class DashboardFinance extends StatefulWidget {
  const DashboardFinance({super.key});

  @override
  State<DashboardFinance> createState() => _DashboardFinanceState();
}

class _DashboardFinanceState extends State<DashboardFinance> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FinanceTransaksiPage(),
    const FinanceProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
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