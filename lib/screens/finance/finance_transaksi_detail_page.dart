import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';

class FinanceTransaksiDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  const FinanceTransaksiDetailPage({super.key, required this.transaksi});

  @override
  State<FinanceTransaksiDetailPage> createState() => _FinanceTransaksiDetailPageState();
}

class _FinanceTransaksiDetailPageState extends State<FinanceTransaksiDetailPage> {
  late Map<String, dynamic> _trx;
  bool _isLoading = false;
  File? _buktiRefundFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _trx = Map<String, dynamic>.from(widget.transaksi);
  }

  String _formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.',
    )}';
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

  // =========================
  // INCREMENT KUOTA
  // =========================
  Future<void> _incrementKuota() async {
    final idTiket = _trx['id_tiket'];
    if (idTiket == null) return;

    final tiketData = await supabase
        .schema('ursaevent')
        .from('tikets')
        .select('kuota')
        .eq('id', idTiket)
        .single();

    final kuota = tiketData['kuota'] ?? 0;

    await supabase
        .schema('ursaevent')
        .from('tikets')
        .update({'kuota': kuota + 1})
        .eq('id', idTiket);

    debugPrint('=== INCREMENT KUOTA: $kuota → ${kuota + 1} ===');
  }

  // =========================
  // KONFIRMASI PEMBAYARAN → AKTIF
  // =========================
  Future<void> _konfirmasiPembayaran() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Apakah pembayaran ini sudah valid?\nStatus akan berubah menjadi "aktif".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .update({'status': 'aktif'})
          .eq('id_transaksi', _trx['id_transaksi']);
      setState(() {
        _trx['status'] = 'aktif';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pembayaran dikonfirmasi, tiket aktif!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal konfirmasi: $e')));
    }
  }

  // =========================
  // TOLAK PEMBAYARAN → 2 PILIHAN
  // =========================
  Future<void> _tolakPembayaran() async {
    // Dialog pilihan jenis penolakan
    final pilihan = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih alasan penolakan:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // PILIHAN 1: Bukti tidak valid → hapus dari DB
            GestureDetector(
              onTap: () => Navigator.pop(context, 'hapus'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_outlined, color: Colors.red.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bukti Tidak Valid / Tidak Ada',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Data transaksi akan dihapus permanen & kuota dikembalikan.',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // PILIHAN 2: Tolak biasa → user bisa refund
            GestureDetector(
              onTap: () => Navigator.pop(context, 'refund'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.replay_outlined, color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tolak & Kembalikan ke User',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status cancel, user bisa mengajukan refund & kuota dikembalikan.',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (pilihan == null) return;

    // -------------------------------------------------------
    // PILIHAN 1: Bukti tidak valid → DELETE transaksi dari DB
    // -------------------------------------------------------
    if (pilihan == 'hapus') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: const Text(
            'Data transaksi ini akan dihapus permanen dari database.\nKuota tiket akan dikembalikan.\n\nAksi ini tidak bisa dibatalkan!',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Hapus Permanen'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        // INCREMENT KUOTA dulu sebelum hapus
        await _incrementKuota();

        // HAPUS TRANSAKSI DARI DATABASE
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .delete()
            .eq('id_transaksi', _trx['id_transaksi']);

        debugPrint('=== TOLAK (HAPUS) → TRANSAKSI DIHAPUS & KUOTA DIKEMBALIKAN ===');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Transaksi dihapus & kuota dikembalikan.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context); // kembali ke list transaksi
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus transaksi: $e')));
      }
      return;
    }

    // -------------------------------------------------------
    // PILIHAN 2: Tolak biasa → status cancel, user bisa refund
    // -------------------------------------------------------
    if (pilihan == 'refund') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tolak & Kembalikan ke User'),
          content: const Text(
            'Status transaksi akan menjadi "cancel".\nUser akan bisa mengajukan refund.\nKuota tiket akan dikembalikan.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Tolak'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        // INCREMENT KUOTA
        await _incrementKuota();

        // UPDATE STATUS → CANCEL (user bisa ajukan refund)
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .update({'status': 'cancel'})
            .eq('id_transaksi', _trx['id_transaksi']);

        setState(() {
          _trx['status'] = 'cancel';
          _isLoading = false;
        });

        debugPrint('=== TOLAK (REFUND) → STATUS CANCEL & KUOTA DIKEMBALIKAN ===');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran ditolak. User dapat mengajukan refund.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
      }
    }
  }

  // =========================
  // PICK BUKTI REFUND
  // =========================
  Future<void> _pickBuktiRefund() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _buktiRefundFile = File(picked.path));
  }

  // =========================
  // PROSES REFUND + UPLOAD BUKTI
  // =========================
  Future<void> _prosesRefund() async {
    if (_buktiRefundFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload bukti refund dulu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Refund'),
        content: const Text('Apakah dana sudah ditransfer ke rekening user?\nStatus akan berubah menjadi "refund".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // UPLOAD BUKTI REFUND KE STORAGE
      final fileName = 'refund_${_trx['id_transaksi']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _buktiRefundFile!.readAsBytes();
      await supabase.storage.from('bukti-bayar').uploadBinary(fileName, bytes);
      final urlBuktiRefund = supabase.storage.from('bukti-bayar').getPublicUrl(fileName);

      // UPDATE STATUS + BUKTI REFUND
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .update({
        'status': 'refund',
        'bukti_refund': urlBuktiRefund,
      })
          .eq('id_transaksi', _trx['id_transaksi']);

      setState(() {
        _trx['status'] = 'refund';
        _trx['bukti_refund'] = urlBuktiRefund;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Refund berhasil diproses!'), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal proses refund: $e')));
    }
  }

  // =========================
  // TOLAK REFUND → 2 PILIHAN
  // =========================
  Future<void> _tolakRefund() async {
    final pilihan = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Pengajuan Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih alasan penolakan refund:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // PILIHAN 1: Tidak sesuai → tolak permanen
            GestureDetector(
              onTap: () => Navigator.pop(context, 'tolak_permanen'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, color: Colors.red.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tolak Permanen (Tidak Sesuai)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Data refund dihapus, status kembali ke "cancel". User tidak bisa ajukan refund lagi.',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // PILIHAN 2: Kembalikan ke user untuk isi ulang
            GestureDetector(
              onTap: () => Navigator.pop(context, 'kembalikan'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kembalikan ke User (Isi Ulang)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Data refund direset, user bisa mengisi ulang info rekening refund.',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (pilihan == null) return;

    // -------------------------------------------------------
    // PILIHAN 1: Tolak permanen → status tetap cancel, hapus data refund
    // -------------------------------------------------------
    if (pilihan == 'tolak_permanen') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tolak Refund Permanen?'),
          content: const Text(
            'Data rekening refund user akan dihapus.\nStatus tetap "cancel" dan user tidak bisa mengajukan refund lagi untuk transaksi ini.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Tolak Permanen'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        // HAPUS TRANSAKSI PERMANEN DARI DATABASE
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .delete()
            .eq('id_transaksi', _trx['id_transaksi']);

        debugPrint('=== TOLAK REFUND PERMANEN → TRANSAKSI DIHAPUS DARI DATABASE ===');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚫 Refund ditolak, transaksi dihapus permanen.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context); // kembali ke list transaksi
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus transaksi: $e')));
      }
      return;
    }

    // -------------------------------------------------------
    // PILIHAN 2: Kembalikan ke user → reset data refund, status cancel
    // -------------------------------------------------------
    if (pilihan == 'kembalikan') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kembalikan ke User?'),
          content: const Text(
            'Data rekening refund akan direset.\nUser dapat mengisi ulang info rekening dan mengajukan refund kembali.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Kembalikan'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      setState(() => _isLoading = true);
      try {
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .update({
          'status': 'cancel',
          'refund_bank': null,
          'refund_no_va': null,
          'refund_nama': null,
        }).eq('id_transaksi', _trx['id_transaksi']);

        setState(() {
          _trx['status'] = 'cancel';
          _trx['refund_bank'] = null;
          _trx['refund_no_va'] = null;
          _trx['refund_nama'] = null;
          _isLoading = false;
        });

        debugPrint('=== TOLAK REFUND → DIKEMBALIKAN KE USER UNTUK ISI ULANG ===');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('↩️ Refund dikembalikan. User bisa isi ulang rekening.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal kembalikan refund: $e')));
      }
    }
  }

  void _lihatGambar(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _GambarViewer(imageUrl: url, title: title)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buktiFotoWidget(String url, String title) {
    return GestureDetector(
      onTap: () => _lihatGambar(url, title),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(height: 200, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 48, color: Colors.grey)),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Tap untuk perbesar', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _trx['status'] as String?;
    final event = _trx['event'] as Map<String, dynamic>?;
    final tiket = _trx['tikets'] as Map<String, dynamic>?;
    final buktiBayar = _trx['bukti_bayar'] as String?;
    final buktiRefund = _trx['bukti_refund'] as String?;
    final isMenunggu = status == 'menunggu konfirmasi';
    final isRefundDiajukan = status == 'refund diajukan';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(status).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _statusColor(status)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Transaksi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        status ?? '-',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _statusColor(status)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // INFO TRANSAKSI
            _sectionCard(
              title: 'Info Transaksi',
              icon: Icons.receipt_long_outlined,
              children: [
                _infoRow(Icons.tag, 'ID Transaksi', _trx['id_transaksi'] ?? '-'),
                const SizedBox(height: 10),
                _infoRow(Icons.event_outlined, 'Event', event?['nama_event'] ?? '-'),
                const SizedBox(height: 10),
                _infoRow(Icons.confirmation_number_outlined, 'Tiket', '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}'),
                const SizedBox(height: 10),
                _infoRow(Icons.calendar_today_outlined, 'Tanggal', _trx['tanggal'] ?? '-'),
                const SizedBox(height: 10),
                _infoRow(Icons.payments_outlined, 'Total', _formatRupiah(_trx['sub_total'])),
              ],
            ),

            const SizedBox(height: 12),

            // BUKTI BAYAR
            _sectionCard(
              title: 'Bukti Pembayaran',
              icon: Icons.image_outlined,
              children: [
                if (buktiBayar == null)
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
                        SizedBox(height: 6),
                        Text('Belum ada bukti bayar', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  _buktiFotoWidget(buktiBayar, 'Bukti Pembayaran'),
              ],
            ),

            // TOMBOL ACC / TOLAK
            if (isMenunggu && buktiBayar != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _tolakPembayaran,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _konfirmasiPembayaran,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],

            // SECTION REFUND DIAJUKAN
            if (isRefundDiajukan) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Pengajuan Refund dari User',
                icon: Icons.replay_outlined,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.account_balance_outlined, 'Bank / Dompet Digital', _trx['refund_bank'] ?? '-'),
                        const SizedBox(height: 10),
                        _infoRow(Icons.credit_card_outlined, 'No. VA / Rekening', _trx['refund_no_va'] ?? '-'),
                        const SizedBox(height: 10),
                        _infoRow(Icons.person_outline, 'Atas Nama', _trx['refund_nama'] ?? '-'),
                        const SizedBox(height: 10),
                        _infoRow(Icons.payments_outlined, 'Jumlah Refund', _formatRupiah(_trx['sub_total'])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UPLOAD BUKTI REFUND
                  const Text('Upload Bukti Transfer Refund', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickBuktiRefund,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _buktiRefundFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_buktiRefundFile!, fit: BoxFit.cover),
                      )
                          : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap untuk pilih foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  if (_buktiRefundFile != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _pickBuktiRefund,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Ganti Foto'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _tolakRefund,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            side: const BorderSide(color: Color(0xFFD32F2F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Tolak Refund', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _prosesRefund,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Tandai Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // BUKTI REFUND (kalau sudah diproses)
            if (status == 'refund' && buktiRefund != null) ...[
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Bukti Transfer Refund',
                icon: Icons.replay_outlined,
                children: [_buktiFotoWidget(buktiRefund, 'Bukti Refund')],
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// FULLSCREEN VIEWER
class _GambarViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  const _GambarViewer({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (_, __, ___) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 64),
                  SizedBox(height: 8),
                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}