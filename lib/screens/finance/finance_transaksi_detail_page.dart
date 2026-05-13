import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
      case 'tiket dikirim': return Colors.green;
      case 'cancel': return Colors.red;
      case 'refund':
      case 'refund diajukan': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Future<void> _konfirmasiPembayaran() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Apakah pembayaran ini sudah valid?\nStatus akan berubah menjadi "tiket dikirim".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase.schema('ursaevent').from('transaksis').update({'status': 'tiket dikirim'}).eq('id_transaksi', _trx['id_transaksi']);
      setState(() { _trx['status'] = 'tiket dikirim'; _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pembayaran dikonfirmasi, tiket telah dikirim!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal konfirmasi: $e')));
    }
  }

  Future<void> _tolakPembayaran() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: const Text('Apakah kamu yakin ingin menolak pembayaran ini?\nUser akan diminta mengajukan refund.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase.schema('ursaevent').from('transaksis').update({'status': 'cancel'}).eq('id_transaksi', _trx['id_transaksi']);
      setState(() { _trx['status'] = 'cancel'; _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran ditolak. User akan diarahkan untuk refund.'), backgroundColor: Colors.red));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
    }
  }

  Future<void> _prosesRefund() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Refund'),
        content: const Text('Apakah dana sudah ditransfer ke rekening user?\nStatus akan berubah menjadi "refund".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase.schema('ursaevent').from('transaksis').update({'status': 'refund'}).eq('id_transaksi', _trx['id_transaksi']);
      setState(() { _trx['status'] = 'refund'; _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Refund berhasil diproses!'), backgroundColor: Colors.teal));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal proses refund: $e')));
    }
  }

  void _lihatBuktiBayar(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _BuktiBayarViewer(imageUrl: url)));
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

  @override
  Widget build(BuildContext context) {
    final status = _trx['status'] as String?;
    final event = _trx['event'] as Map<String, dynamic>?;
    final tiket = _trx['tikets'] as Map<String, dynamic>?;
    final buktiBayar = _trx['bukti_bayar'] as String?;
    final isMenunggu = status == 'menunggu konfirmasi';
    final isRefundDiajukan = status == 'refund diajukan';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS BADGE
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                ),
                child: Text(
                  (status ?? '-').toUpperCase(),
                  style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // INFO TRANSAKSI
            _sectionCard(
              title: 'Informasi Transaksi',
              icon: Icons.receipt_long_outlined,
              children: [
                _infoRow(Icons.tag, 'ID Transaksi', _trx['id_transaksi'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.calendar_today_outlined, 'Tanggal', _trx['tanggal'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.confirmation_number_outlined, 'Qty', '${_trx['qty'] ?? 1} tiket'),
                const SizedBox(height: 12),
                _infoRow(Icons.payments_outlined, 'Total Pembayaran', _formatRupiah(_trx['sub_total'])),
              ],
            ),

            const SizedBox(height: 12),

            // INFO EVENT
            _sectionCard(
              title: 'Informasi Event',
              icon: Icons.event_outlined,
              children: [
                _infoRow(Icons.celebration_outlined, 'Nama Event', event?['nama_event'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.calendar_month_outlined, 'Tanggal Event', event?['tanggal'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.confirmation_number_outlined, 'Nama Tiket', tiket?['nama_tiket'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.category_outlined, 'Kategori', tiket?['kategori'] ?? '-'),
                const SizedBox(height: 12),
                _infoRow(Icons.sell_outlined, 'Harga Satuan', _formatRupiah(tiket?['harga'])),
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
                  GestureDetector(
                    onTap: () => _lihatBuktiBayar(buktiBayar),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: buktiBayar,
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
                  ),
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
                      label: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _prosesRefund,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Tandai Refund Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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
class _BuktiBayarViewer extends StatelessWidget {
  final String imageUrl;
  const _BuktiBayarViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Bukti Pembayaran', style: TextStyle(color: Colors.white)),
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