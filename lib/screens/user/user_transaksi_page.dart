import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'user_refund_page.dart';
import 'user_detail_transaksi_page.dart';
import 'user_booking_page.dart';

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
            tikets:id_tiket(nama_tiket, kategori, harga, id_event)
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

  // =========================
  // HANDLE TAP TRANSAKSI HOLDING
  // =========================
  Future<void> _handleTapHolding(Map<String, dynamic> trx) async {
    final expiredAtStr = trx['expired_at'] as String?;
    if (expiredAtStr == null) return;

    final expiredAt = DateTime.tryParse(expiredAtStr);
    if (expiredAt == null) return;

    final now = DateTime.now();

    if (now.isAfter(expiredAt)) {
      // Sudah expired, cancel dan kembalikan kuota
      try {
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .delete()
            .eq('id_transaksi', trx['id_transaksi']);

        // Kurangi kuota via update langsung
        final tiketData = await supabase
            .schema('ursaevent')
            .from('tikets')
            .select('kuota')
            .eq('id', trx['id_tiket'])
            .single();

        final kuota = tiketData['kuota'] ?? 0;
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .update({'kuota': kuota + 1})
            .eq('id', trx['id_tiket']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi sudah expired dan dibatalkan otomatis.'),
              backgroundColor: Colors.red,
            ),
          );
          _fetchTransaksi();
        }
      } catch (e) {
        debugPrint('ERROR CANCEL EXPIRED: $e');
      }
      return;
    }

    // Belum expired, buka booking page dengan mode resume
    final tiket = trx['tikets'] as Map<String, dynamic>? ?? {};
    final event = trx['event'] as Map<String, dynamic>? ?? {};

    // Tambah id ke tiket dan event supaya bisa dipakai booking page
    tiket['id'] = trx['id_tiket'];
    event['id_event'] = trx['id_event'];

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserBookingPage(
          tiket: tiket,
          event: event,
          existingIdTransaksi: trx['id_transaksi'],
          existingExpiredAt: expiredAt,
        ),
      ),
    );

    _fetchTransaksi();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'holding': return Colors.purple;
      case 'menunggu konfirmasi': return Colors.orange;
      case 'dikonfirmasi': return Colors.blue;
      case 'aktif': return Colors.green;
      case 'cancel': return Colors.red;
      case 'refund':
      case 'refund diajukan': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'holding': return Icons.timer_outlined;
      case 'menunggu konfirmasi': return Icons.hourglass_empty_outlined;
      case 'dikonfirmasi': return Icons.check_circle_outline;
      case 'aktif': return Icons.confirmation_number_outlined;
      case 'cancel': return Icons.cancel_outlined;
      case 'refund':
      case 'refund diajukan': return Icons.replay_outlined;
      default: return Icons.info_outline;
    }
  }

  void _lihatBuktiRefund(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Bukti Refund', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey)),
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
            final buktiRefund = trx['bukti_refund'] as String?;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: status == 'aktif'
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailTransaksiPage(trx: trx),
                  ),
                );
              }
                  : status == 'holding'
                  ? () => _handleTapHolding(trx)
                  : null,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                                const SizedBox(width: 4),
                                Text(
                                  status ?? '-',
                                  style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(event?['tanggal'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // TOTAL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            'Rp ${trx['sub_total'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F), fontSize: 14),
                          ),
                        ],
                      ),

                      // HINT HOLDING
                      if (status == 'holding') ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 14, color: Colors.purple.shade700),
                              const SizedBox(width: 6),
                              Text('Tap untuk lanjutkan pembayaran', style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
                            ],
                          ),
                        ),
                      ],

                      // TOMBOL AJUKAN REFUND (kalau cancel)
                      if (status == 'cancel') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserRefundPage(
                                    idTransaksi: trx['id_transaksi'],
                                    subTotal: trx['sub_total'],
                                  ),
                                ),
                              );
                              _fetchTransaksi();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.replay_outlined, size: 16),
                            label: const Text('Ajukan Refund', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],

                      // LIHAT BUKTI REFUND
                      if (status == 'refund' && buktiRefund != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _lihatBuktiRefund(buktiRefund),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('Lihat Bukti Refund', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],

                      // INFO REFUND DIAJUKAN
                      if (status == 'refund diajukan') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty_outlined, size: 14, color: Colors.teal.shade700),
                              const SizedBox(width: 6),
                              Text('Refund sedang diproses oleh finance', style: TextStyle(fontSize: 12, color: Colors.teal.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}