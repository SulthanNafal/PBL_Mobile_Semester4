import 'package:flutter/material.dart';
import '../../main.dart';

class UserTransaksiPage extends StatefulWidget {
  const UserTransaksiPage({super.key});

  @override
  State<UserTransaksiPage> createState() => _UserTransaksiPageState();
}

class _UserTransaksiPageState extends State<UserTransaksiPage> {
  List<Map<String, dynamic>> _transaksi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransaksi();
  }

  Future<void> _fetchTransaksi() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select()
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _transaksi = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancel':
        return Colors.red;
      case 'refund':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _transaksi.isEmpty
          ? const Center(
        child: Text(
          'Belum ada transaksi.',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        color: const Color(0xFFD32F2F),
        onRefresh: _fetchTransaksi,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _transaksi.length,
          itemBuilder: (context, index) {
            final trx = _transaksi[index];
            final status = trx['status'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          'ID: ${trx['id_transaksi']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status ?? '-',
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Tanggal: ${trx['tanggal'] ?? '-'}'),
                    Text(
                      'Total: Rp ${trx['sub_total'] ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}