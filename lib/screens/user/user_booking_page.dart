import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';
import 'user_upload_bukti_page.dart';

class UserBookingPage extends StatefulWidget {
  final Map<String, dynamic> tiket;
  final Map<String, dynamic> event;

  const UserBookingPage({
    super.key,
    required this.tiket,
    required this.event,
  });

  @override
  State<UserBookingPage> createState() => _UserBookingPageState();
}

class _UserBookingPageState extends State<UserBookingPage> {
  Timer? _timer;
  int _sisaDetik = 30 * 60;
  bool _isLoading = true;
  bool _isTimeout = false;
  int? _idTransaksi;
  String _username = '-';
  String _nama = '-';

  @override
  void initState() {
    super.initState();
    _buatTransaksi();
  }

  // =========================
  // BUAT TRANSAKSI + HOLD KUOTA
  // =========================
  Future<void> _buatTransaksi() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // FETCH USERNAME & NAMA
      final userData = await supabase
          .schema('ursaevent')
          .from('users')
          .select('username, name')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null) {
        _username = userData['username'] ?? '-';
        _nama = userData['name'] ?? '-';
      }

      final now = DateTime.now();
      final expiredAt = now.add(const Duration(minutes: 30));

      // INSERT TRANSAKSI
      final result = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .insert({
        'id_user': user.id,
        'id_tiket': widget.tiket['id'],
        'id_event': widget.event['id_event'],
        'sub_total': widget.tiket['harga'],
        'tanggal': now.toIso8601String().split('T')[0],
        'waktu': now.toIso8601String().split('T')[1].substring(0, 8),
        'status': 'holding',
        'expired_at': expiredAt.toIso8601String(),
      })
          .select()
          .single();

      // KURANGI KUOTA
      await supabase
          .schema('ursaevent')
          .from('tikets')
          .update({'kuota': widget.tiket['kuota'] - 1})
          .eq('id', widget.tiket['id']);

      setState(() {
        _idTransaksi = result['id_transaksi'];
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat transaksi: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // =========================
  // TIMER COUNTDOWN
  // =========================
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaDetik <= 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() => _sisaDetik--);
      }
    });
  }

  // =========================
  // TIMEOUT → CANCEL TRANSAKSI
  // =========================
  Future<void> _handleTimeout() async {
    setState(() => _isTimeout = true);

    try {
      await supabase
          .schema('ursaevent')
          .from('tikets')
          .update({'kuota': widget.tiket['kuota'] + 1})
          .eq('id', widget.tiket['id']);

      if (_idTransaksi != null) {
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .update({'status': 'cancel'})
            .eq('id_transaksi', _idTransaksi!);
      }
    } catch (_) {}

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Waktu Habis!'),
          content: const Text(
            'Batas waktu pemesanan telah habis.\nTransaksi dibatalkan otomatis dan kuota dikembalikan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.user,
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTimer() {
    final menit = (_sisaDetik ~/ 60).toString().padLeft(2, '0');
    final detik = (_sisaDetik % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  Color _timerColor() {
    if (_sisaDetik > 10 * 60) return Colors.green;
    if (_sisaDetik > 5 * 60) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Tiket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD32F2F)),
            SizedBox(height: 16),
            Text('Memproses booking...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // COUNTDOWN TIMER
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _timerColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _timerColor().withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Selesaikan pembayaran dalam',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimer(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _timerColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sisaDetik <= 5 * 60
                        ? 'Segera selesaikan pembayaran!'
                        : 'Kuota tiket sudah direservasi untuk Anda',
                    style: TextStyle(fontSize: 12, color: _timerColor()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // DETAIL PEMESAN
            // =========================
            const Text(
              'Detail Pemesan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow('Nama', _nama),
                  _buildRow('Username', _username),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // DETAIL PESANAN
            // =========================
            const Text(
              'Detail Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow('Event', widget.event['nama_event'] ?? '-'),
                  _buildRow('Tanggal Event', widget.event['tanggal'] ?? '-'),
                  _buildRow('Tiket', widget.tiket['nama_tiket'] ?? '-'),
                  _buildRow('Kategori', widget.tiket['kategori'] ?? '-'),
                  const Divider(),
                  _buildRow(
                    'Total Pembayaran',
                    'Rp ${widget.tiket['harga'] ?? 0}',
                    isBold: true,
                    valueColor: const Color(0xFFD32F2F),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // INFO PEMBAYARAN
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Informasi Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Lakukan transfer ke rekening yang tertera\n'
                        '2. Upload bukti transfer\n'
                        '3. Tunggu konfirmasi dari tim kami\n'
                        '4. Tiket akan dikirim setelah pembayaran dikonfirmasi',
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // =========================
            // TOMBOL UPLOAD BUKTI
            // =========================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTimeout
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserUploadBuktiPage(
                        idTransaksi: _idTransaksi!,
                        tiket: widget.tiket,
                        event: widget.event,
                        timer: _timer,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.upload_outlined),
                label: const Text(
                  'Upload Bukti Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // TOMBOL BATAL
            // =========================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isTimeout ? null : _handleBatal,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Batalkan Pesanan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BATAL MANUAL
  // =========================
  Future<void> _handleBatal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Kuota tiket akan dikembalikan jika kamu membatalkan pesanan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _timer?.cancel();
      try {
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .update({'kuota': widget.tiket['kuota'] + 1})
            .eq('id', widget.tiket['id']);

        if (_idTransaksi != null) {
          await supabase
              .schema('ursaevent')
              .from('transaksis')
              .update({'status': 'cancel'})
              .eq('id_transaksi', _idTransaksi!);
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.user,
              (route) => false,
        );
      }
    }
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}