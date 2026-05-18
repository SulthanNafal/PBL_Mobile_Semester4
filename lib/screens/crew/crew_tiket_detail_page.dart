import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class CrewTiketDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaksi;

  const CrewTiketDetailPage({super.key, required this.transaksi});

  @override
  State<CrewTiketDetailPage> createState() => _CrewTiketDetailPageState();
}

class _CrewTiketDetailPageState extends State<CrewTiketDetailPage> {
  late Map<String, dynamic> _trx;
  bool _isLoading = false;

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
      case 'aktif': return Colors.green;
      case 'expired': return Colors.grey;
      case 'cancel': return Colors.red;
      case 'refund':
      case 'refund diajukan': return Colors.teal;
      case 'menunggu konfirmasi': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // =========================
  // ACCEPT TIKET → EXPIRED
  // =========================
  Future<void> _acceptTiket() async {
    final status = _trx['status'] as String?;

    if (status != 'aktif') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(
                status == 'expired' ? Icons.check_circle : Icons.warning_amber_rounded,
                color: status == 'expired' ? Colors.grey : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(status == 'expired' ? 'Tiket Sudah Digunakan' : 'Tiket Tidak Valid'),
            ],
          ),
          content: Text(
            status == 'expired'
                ? 'Tiket ini sudah pernah digunakan sebelumnya.'
                : 'Tiket dengan status "$status" tidak dapat diterima.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Terima Tiket?'),
          ],
        ),
        content: const Text(
          'Konfirmasi penerimaan tiket ini?\nStatus tiket akan berubah menjadi "expired" setelah diterima.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Terima'),
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
          .update({'status': 'expired'})
          .eq('id_transaksi', _trx['id_transaksi']);

      setState(() {
        _trx['status'] = 'expired';
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Berhasil!'),
              ],
            ),
            content: const Text('Tiket berhasil diterima.\nPeserta dipersilakan masuk.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pop(context); // kembali ke scanner
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Selesai'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima tiket: $e')),
        );
      }
    }
  }

  Widget _infoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black,
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
    final user = _trx['users'] as Map<String, dynamic>?;
    final isAktif = status == 'aktif';
    final isExpired = status == 'expired';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Detail Tiket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
        child: Column(
          children: [

            // =========================
            // FOTO EVENT
            // =========================
            if (event?['foto'] != null)
              CachedNetworkImage(
                imageUrl: event!['foto'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              )
            else
              Container(
                height: 160,
                color: const Color(0xFFD32F2F).withOpacity(0.1),
                child: const Center(
                  child: Icon(Icons.event, size: 64, color: Color(0xFFD32F2F)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =========================
                  // STATUS BADGE
                  // =========================
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAktif ? Icons.check_circle_outline
                                : isExpired ? Icons.do_not_disturb_on_outlined
                                : Icons.cancel_outlined,
                            size: 18,
                            color: _statusColor(status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAktif ? 'TIKET VALID'
                                : isExpired ? 'SUDAH DIGUNAKAN'
                                : 'TIKET TIDAK VALID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _statusColor(status),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // INFO EVENT
                  // =========================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_outlined, size: 18, color: Color(0xFFD32F2F)),
                            SizedBox(width: 8),
                            Text('Info Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow('Nama Event', event?['nama_event'] ?? '-', isBold: true),
                        _infoRow('Tanggal', event?['tanggal'] ?? '-'),
                        _infoRow('Jam', event?['jam'] ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // INFO TIKET
                  // =========================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFFD32F2F)),
                            SizedBox(width: 8),
                            Text('Info Tiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow('ID Transaksi', _trx['id_transaksi'] ?? '-'),
                        _infoRow('Nama Tiket', tiket?['nama_tiket'] ?? '-'),
                        _infoRow('Kategori', tiket?['kategori'] ?? '-', isBold: true),
                        _infoRow('Harga', _formatRupiah(tiket?['harga']), valueColor: const Color(0xFFD32F2F), isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // INFO PEMILIK
                  // =========================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline, size: 18, color: Color(0xFFD32F2F)),
                            SizedBox(width: 8),
                            Text('Pemilik Tiket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow('Nama', user?['name'] ?? '-', isBold: true),
                        _infoRow('Username', user?['username'] ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // TOMBOL ACCEPT / SUDAH DIPAKAI
                  // =========================
                  if (isAktif) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _acceptTiket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: const Text(
                          'Terima Tiket',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else if (isExpired) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.do_not_disturb_on_outlined, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tiket sudah digunakan',
                            style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tiket tidak valid (${status ?? '-'})',
                            style: TextStyle(color: Colors.red.shade600, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // TOMBOL SCAN LAGI
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text(
                        'Scan Tiket Lain',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}