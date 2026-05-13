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
          .select('''
            *,
            event:id_event(nama_event, tanggal),
            tikets:id_tiket(nama_tiket, kategori)
          ''')
          .eq('id_user', user.id)
          .order('tanggal', ascending: false);

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
      case 'holding':
        return Colors.purple;
      case 'menunggu konfirmasi':
        return Colors.orange;
      case 'dikonfirmasi':
        return Colors.blue;
      case 'tiket dikirim':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'refund':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'holding':
        return Icons.timer_outlined;
      case 'menunggu konfirmasi':
        return Icons.hourglass_empty_outlined;
      case 'dikonfirmasi':
        return Icons.check_circle_outline;
      case 'tiket dikirim':
        return Icons.confirmation_number_outlined;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'refund':
        return Icons.replay_outlined;
      default:
        return Icons.info_outline;
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
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
      )
          : _transaksi.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Belum ada transaksi.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
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
            final event = trx['event'] as Map<String, dynamic>?;
            final tiket = trx['tikets'] as Map<String, dynamic>?;

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

                    // STATUS + ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trx['id_transaksi'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(status),
                                size: 12,
                                color: _statusColor(status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status ?? '-',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 16),

                    // INFO EVENT & TIKET
                    Text(
                      event?['nama_event'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event?['tanggal'] ?? '-',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // TOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          'Rp ${trx['sub_total'] ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                          ),
                        ),
                      ],
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