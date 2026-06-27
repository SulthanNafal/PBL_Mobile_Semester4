import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';
import 'user_upload_bukti_page.dart';

class UserBookingPage extends StatefulWidget {
  final Map<String, dynamic> tiket;
  final Map<String, dynamic> event;
  final int jumlah;

  // MODE RESUME: kalau ada transaksi holding yang belum expired
  final String? existingIdTransaksi;
  final DateTime? existingExpiredAt;

  const UserBookingPage({
    super.key,
    required this.tiket,
    required this.event,
    required this.jumlah,
    this.existingIdTransaksi,
    this.existingExpiredAt,
  });

  @override
  State<UserBookingPage> createState() => _UserBookingPageState();
}

class _UserBookingPageState extends State<UserBookingPage> {
  Timer? _timer;
  int _sisaDetik = 30 * 60;
  bool _isLoading = true;
  bool _isTimeout = false;
  bool _sudahBuat = false;
  String? _idTransaksi;
  String _username = '-';
  String _nama = '-';

  bool get _isResumeMode => widget.existingIdTransaksi != null && widget.existingExpiredAt != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isResumeMode) {
        _resumeTransaksi();
      } else if (!_sudahBuat) {
        _buatTransaksi();
      }
    });
  }

  // =========================
  // GENERATE ID TRANSAKSI
  // =========================
  String _generateIdTransaksi() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final tahun = DateTime.now().year;
    final randomString = List.generate(
      20,
          (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'URSA-$tahun-$randomString';
  }

  // =========================
  // DECREMENT KUOTA
  // =========================
  Future<void> _decrementKuota() async {
    final tiketData = await supabase
        .schema('ursaevent')
        .from('tikets')
        .select('kuota')
        .eq('id', widget.tiket['id'])
        .single();

    final kuota = tiketData['kuota'] ?? 0;

    final jumlah = widget.tiket['jumlah'] ?? 1;

    if (kuota < jumlah) {
      throw Exception('Kuota tiket tidak mencukupi');
    }

    await supabase
        .schema('ursaevent')
        .from('tikets')
        .update({
      'kuota': kuota - jumlah,
    })
        .eq('id', widget.tiket['id']);

    debugPrint(
        '=== DECREMENT KUOTA: $kuota → ${kuota - jumlah} ===');
  }

  // =========================
  // INCREMENT KUOTA
  // =========================
  Future<void> _incrementKuota() async {
    final tiketData = await supabase
        .schema('ursaevent')
        .from('tikets')
        .select('kuota')
        .eq('id', widget.tiket['id'])
        .single();

    final kuota = tiketData['kuota'] ?? 0;

    final jumlah = widget.tiket['jumlah'] ?? 1;

    await supabase
        .schema('ursaevent')
        .from('tikets')
        .update({
      'kuota': kuota + jumlah,
    })
        .eq('id', widget.tiket['id']);

    debugPrint(
        '=== INCREMENT KUOTA: $kuota → ${kuota + jumlah} ===');
  }

  // =========================
  // RESUME TRANSAKSI YANG ADA
  // =========================
  Future<void> _resumeTransaksi() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pop(context);
        return;
      }

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

      // HITUNG SISA WAKTU DARI expired_at
      final now = DateTime.now();
      final expiredAt = widget.existingExpiredAt!;
      final sisaDetik = expiredAt.difference(now).inSeconds;

      if (sisaDetik <= 0) {
        // Sudah expired, cancel langsung
        await _cancelExpiredTransaksi(widget.existingIdTransaksi!);
        return;
      }

      if (!mounted) return;

      setState(() {
        _idTransaksi = widget.existingIdTransaksi;
        _sisaDetik = sisaDetik;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('ERROR RESUME TRANSAKSI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // =========================
  // CANCEL TRANSAKSI YANG EXPIRED
  // =========================
  Future<void> _cancelExpiredTransaksi(String idTransaksi) async {
    try {
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .delete()
          .eq('id_transaksi', idTransaksi);

      await _incrementKuota();
    } catch (e) {
      debugPrint('ERROR CANCEL EXPIRED: $e');
    }

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

  // =========================
  // BUAT TRANSAKSI BARU
  // =========================
  Future<void> _buatTransaksi() async {
    if (_sudahBuat) return;
    _sudahBuat = true;

    debugPrint('=== _buatTransaksi dipanggil ===');

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pop(context);
        return;
      }

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
      final idTransaksi = _generateIdTransaksi();

      // CEK & KURANGI KUOTA
      await _decrementKuota();

      final jumlah = widget.tiket['jumlah'] ?? widget.jumlah;

      final harga = widget.tiket['harga'] ?? 0;

      final subtotal = harga * jumlah;

      final ppn = (subtotal * 0.11).round();

      final totalBayar = subtotal + ppn;

      // INSERT TRANSAKSI
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .insert({
        'id_transaksi': idTransaksi,
        'id_user': user.id,
        'id_tiket': widget.tiket['id'],
        'id_event': widget.event['id_event'],
        'sub_total': totalBayar,
        'jumlah': jumlah,
        'tanggal': now.toIso8601String().split('T')[0],
        'waktu': now.toIso8601String().split('T')[1].substring(0, 8),
        'status': 'holding',
        'expired_at': expiredAt.toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _idTransaksi = idTransaksi;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('ERROR BUAT TRANSAKSI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal booking tiket: $e')),
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
        if (mounted) setState(() => _sisaDetik--);
      }
    });
  }

  // =========================
  // TIMEOUT → HAPUS TRANSAKSI
  // =========================
  Future<void> _handleTimeout() async {
    if (_isTimeout) return;
    _timer?.cancel();
    setState(() => _isTimeout = true);

    try {
      if (_idTransaksi == null) return;

      final transaksi = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('status')
          .eq('id_transaksi', _idTransaksi!)
          .single();

      if (transaksi['status'] != 'holding') return;

      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .delete()
          .eq('id_transaksi', _idTransaksi!);

      await _incrementKuota();
      debugPrint('=== TIMEOUT → TRANSAKSI DIHAPUS & KUOTA DIKEMBALIKAN ===');
    } catch (e) {
      debugPrint('ERROR TIMEOUT: $e');
    }

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

  // =========================
  // BATAL MANUAL
  // =========================
  Future<void> _handleBatal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Kuota tiket akan dikembalikan jika kamu membatalkan pesanan.',
        ),
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

    if (confirm != true) return;

    try {
      _timer?.cancel();
      if (_idTransaksi == null) return;

      final transaksi = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('status')
          .eq('id_transaksi', _idTransaksi!)
          .single();

      if (transaksi['status'] != 'holding') return;

      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .delete()
          .eq('id_transaksi', _idTransaksi!);

      await _incrementKuota();
      debugPrint('=== BATAL → TRANSAKSI DIHAPUS & KUOTA DIKEMBALIKAN ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.user,
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('ERROR BATAL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan pesanan: $e')),
        );
      }
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
        title: Text(
          _isResumeMode ? 'Lanjutkan Pembayaran' : 'Booking Tiket',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

            // INFO RESUME
            if (_isResumeMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kamu punya pembayaran yang belum selesai. Selesaikan sebelum waktu habis!',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // COUNTDOWN TIMER
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

            // ID TRANSAKSI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ID Transaksi',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _idTransaksi ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DETAIL PEMESAN
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

            // DETAIL PESANAN
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
                    'Jumlah Tiket',
                    '${widget.jumlah}',
                  ),

                  _buildRow(
                    'Subtotal',
                    'Rp ${((widget.tiket['harga'] ?? 0) * widget.jumlah)}',
                  ),

                  _buildRow(
                    'PPN 11%',
                    'Rp ${((((widget.tiket['harga'] ?? 0) * widget.jumlah) * 0.11).round())}',
                  ),

                  _buildRow(
                    'Total Pembayaran',
                    'Rp ${(((widget.tiket['harga'] ?? 0) * widget.jumlah) + ((((widget.tiket['harga'] ?? 0) * widget.jumlah) * 0.11).round()))}',
                    isBold: true,
                    valueColor: const Color(0xFFD32F2F),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // INFO PEMBAYARAN
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
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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

            // TOMBOL UPLOAD BUKTI
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isTimeout || _idTransaksi == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserUploadBuktiPage(
                        idTransaksi: _idTransaksi!,
                        tiket: {
                          ...widget.tiket,

                          'harga': (((widget.tiket['harga'] ?? 0) * widget.jumlah) +
                              ((((widget.tiket['harga'] ?? 0) * widget.jumlah) * 0.11).round())),

                          'jumlah': widget.jumlah,
                        },
                        event: widget.event,
                        jumlah: widget.jumlah,
                        timer: _timer,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_outlined),
                label: const Text(
                  'Upload Bukti Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TOMBOL BATAL
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isTimeout ? null : _handleBatal,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
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