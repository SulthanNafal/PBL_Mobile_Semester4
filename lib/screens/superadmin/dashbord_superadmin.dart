import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
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
        selectedItemColor: const Color(0xFFD32F2F),
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

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  State<SuperadminDashboardPage> createState() =>
      _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTopCategories() async {
    try {
      // 1. Ambil data id_tiket, status, dan jumlah dari tabel transaksis
      final List<dynamic> transaksis = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('id_tiket, status, jumlah');

      if (transaksis.isEmpty) return [];

      // 2. Filter transaksi sah (termasuk 'expired' terpakai, abaikan 'refund')
      final transaksiValid = transaksis.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();

        return status == 'aktif' ||
            status == 'berhasil' ||
            status == 'paid' ||
            status == 'expired';
      }).toList();

      if (transaksiValid.isEmpty) return [];

      // 3. Rekap jumlah tiket terjual per id_tiket dari kolom 'jumlah'
      Map<dynamic, int> hitungTiket = {};
      for (var item in transaksiValid) {
        var idTiket = item['id_tiket'];
        int qty = int.tryParse(item['jumlah']?.toString() ?? '1') ?? 1;

        if (idTiket != null) {
          hitungTiket[idTiket] = (hitungTiket[idTiket] ?? 0) + qty;
        }
      }

      if (hitungTiket.isEmpty) return [];

      // 4. Ambil data kategori & id_event dari tabel tikets
      List<dynamic> listIdTiket = hitungTiket.keys.toList();
      final List<dynamic> tikets = await supabase
          .schema('ursaevent')
          .from('tikets')
          .select('id, kategori, id_event')
          .filter('id', 'in', listIdTiket);

      if (tikets.isEmpty) return [];

      // Ambil seluruh id_event unik untuk query ke tabel event
      List<dynamic> listIdEvent = tikets
          .map((t) => t['id_event'])
          .where((id) => id != null)
          .toSet()
          .toList();

      // Fetch nama_event dari tabel event
      Map<String, String> mapNamaEvent = {};
      if (listIdEvent.isNotEmpty) {
        final List<dynamic> events = await supabase
            .schema('ursaevent')
            .from('event')
            .select('id_event, nama_event')
            .filter('id_event', 'in', listIdEvent);

        for (var e in events) {
          String idEv = e['id_event'].toString();
          mapNamaEvent[idEv] = e['nama_event']?.toString() ?? 'Unknown Event';
        }
      }

      // 5. Rekap total per kombinasi Nama Event & Kategori
      Map<String, Map<String, dynamic>> rekapKategori = {};

      for (var t in tikets) {
        String idEventStr = t['id_event']?.toString() ?? '';
        String namaEvent = mapNamaEvent[idEventStr] ?? 'Event Tidak Ditemukan';
        String kategori = t['kategori']?.toString() ?? 'Lainnya';

        int totalTerjual = hitungTiket[t['id']] ?? 0;
        String groupKey = "$namaEvent|$kategori";

        if (rekapKategori.containsKey(groupKey)) {
          rekapKategori[groupKey]!['jumlah'] =
              (rekapKategori[groupKey]!['jumlah'] as int) + totalTerjual;
        } else {
          rekapKategori[groupKey] = {
            "nama_event": namaEvent,
            "kategori": kategori,
            "jumlah": totalTerjual,
          };
        }
      }

      // 6. Format ke List & Urutkan dari terbanyak
      List<Map<String, dynamic>> hasil = rekapKategori.values.toList();
      hasil.sort((a, b) => (b['jumlah'] as int).compareTo(a['jumlah'] as int));

      return hasil;
    } catch (e) {
      debugPrint("Error fetching categories for Superadmin: $e");
      rethrow;
    }
  }

  // Navigasi Logout yang disesuaikan dengan AppRoutes.login
  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text(
          "Dashboard Superadmin",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getTopCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text("Belum ada data penjualan tiket"),
            );
          }

          double maxValue = data.first['jumlah'].toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Penjualan Berdasarkan Kategori",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...data.asMap().entries.map((e) {
                  int index = e.key;
                  var item = e.value;
                  double value = item['jumlah'].toDouble();

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Peringkat #${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "${item['jumlah']} tiket terjual",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Menampilkan Nama Event
                          Row(
                            children: [
                              const Icon(
                                Icons.event,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['nama_event'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Menampilkan Kategori Tiket
                          Text(
                            item['kategori'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: maxValue > 0 ? value / maxValue : 0,
                            minHeight: 14,
                            borderRadius: BorderRadius.circular(20),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}