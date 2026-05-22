import 'package:flutter/material.dart';
import '../../main.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  State<SuperadminDashboardPage> createState() => _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {

  Future<Map<String, dynamic>> getSummaryStats() async {
    final allTransaksi = await supabase
        .schema('ursaevent')
        .from('transaksis')
        .select('status,sub_total');

    final aktif = allTransaksi.where((t) => t['status'] == 'aktif').length;
    final menunggu = allTransaksi.where((t) => t['status'] == 'menunggu konfirmasi').length;

    final totalPendapatan = allTransaksi
        .where((t) => t['status'] == 'aktif')
        .fold(0.0, (sum, t) => sum + ((t['sub_total'] ?? 0) as num));

    final totalEvent = await supabase
        .schema('ursaevent')
        .from('event')
        .select('id');

    return {
      'aktif': aktif,
      'menunggu': menunggu,
      'totalPendapatan': totalPendapatan,
      'totalEvent': totalEvent.length,
    };
  }

  Future<List<Map<String, dynamic>>> getTopTickets() async {
    final transaksi = await supabase
        .schema('ursaevent')
        .from('transaksis')
        .select('id_tiket,status')
        .eq('status', 'aktif');

    Map<int, int> jumlahTiket = {};
    for (var item in transaksi) {
      int id = item['id_tiket'];
      jumlahTiket[id] = (jumlahTiket[id] ?? 0) + 1;
    }

    List<Map<String, dynamic>> hasil = [];
    for (var item in jumlahTiket.entries) {
      final tiket = await supabase
          .schema('ursaevent')
          .from('tikets')
          .select('nama_tiket,kategori')
          .eq('id', item.key)
          .single();

      hasil.add({
        'nama': tiket['nama_tiket'],
        'kategori': tiket['kategori'],
        'jumlah': item.value,
      });
    }

    hasil.sort((a, b) => b['jumlah'].compareTo(a['jumlah']));
    return hasil.take(5).toList();
  }

  String _formatRupiah(double value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text(
          'Dashboard Superadmin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD32F2F),
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              FutureBuilder<Map<String, dynamic>>(
                future: getSummaryStats(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                      ),
                    );
                  }
                  if (!snap.hasData) return const SizedBox();
                  final s = snap.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ringkasan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _statCard('Total Event', '${s['totalEvent']}',
                              Icons.event, Colors.blue),
                          _statCard('Transaksi Aktif', '${s['aktif']}',
                              Icons.check_circle_outline, Colors.green),
                          _statCard('Menunggu', '${s['menunggu']}',
                              Icons.hourglass_empty, Colors.orange),
                          _statCard(
                            'Pendapatan',
                            _formatRupiah((s['totalPendapatan'] as num).toDouble()),
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFFD32F2F),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              const Text('Top 5 Tiket Terlaris',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: getTopTickets(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final data = snap.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Belum ada data tiket terjual'));
                  }

                  final maxValue = data.first['jumlah'].toDouble();
                  return Column(
                    children: data.asMap().entries.map((e) {
                      final index = e.key;
                      final item = e.value;
                      final value = (item['jumlah'] as int).toDouble();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Terlaris #${index + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('${item['jumlah']} terjual',
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item['nama'],
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Kategori: ${item['kategori']}',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: value / maxValue,
                                minHeight: 16,
                                borderRadius: BorderRadius.circular(20),
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFD32F2F)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}