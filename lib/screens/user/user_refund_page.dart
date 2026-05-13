import 'package:flutter/material.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';

class UserRefundPage extends StatefulWidget {
  final String idTransaksi;
  final dynamic subTotal;

  const UserRefundPage({super.key, required this.idTransaksi, required this.subTotal});

  @override
  State<UserRefundPage> createState() => _UserRefundPageState();
}

class _UserRefundPageState extends State<UserRefundPage> {
  final _noVaController = TextEditingController();
  final _namaController = TextEditingController();
  bool _isLoading = false;
  String? _selectedBank;

  final List<String> _bankOptions = ['BCA','BNI','BRI','Mandiri','BSI','CIMB Niaga','Danamon','GoPay','OVO','Dana','ShopeePay','Lainnya'];

  String _formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _ajukanRefund() async {
    if (_selectedBank == null || _noVaController.text.trim().isEmpty || _namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data rekening!'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.schema('ursaevent').from('transaksis').update({
        'status': 'refund diajukan',
        'refund_bank': _selectedBank,
        'refund_no_va': _noVaController.text.trim(),
        'refund_nama': _namaController.text.trim(),
      }).eq('id_transaksi', widget.idTransaksi);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Refund Diajukan!'),
            content: const Text('Pengajuan refund berhasil dikirim.\nTim finance akan memproses refund ke rekening yang kamu berikan.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.user, (route) => false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengajukan refund: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _noVaController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Refund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade600, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pembayaran Ditolak', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                        const SizedBox(height: 4),
                        Text('Isi data rekening di bawah untuk proses refund.', style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // JUMLAH REFUND
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jumlah Refund', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_formatRupiah(widget.subTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.account_balance_wallet_outlined, color: Colors.teal.shade700, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Data Rekening Tujuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Dana akan ditransfer ke rekening berikut', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // PILIH BANK
            DropdownButtonFormField<String>(
              value: _selectedBank,
              decoration: InputDecoration(
                labelText: 'Bank / Dompet Digital',
                prefixIcon: const Icon(Icons.account_balance_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              hint: const Text('Pilih bank / dompet digital'),
              items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBank = val),
            ),

            const SizedBox(height: 16),

            // NO VA
            TextField(
              controller: _noVaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'No. Virtual Account / No. Rekening',
                hintText: 'Contoh: 1234567890',
                prefixIcon: const Icon(Icons.credit_card_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),

            const SizedBox(height: 16),

            // NAMA
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Pemilik Rekening',
                hintText: 'Sesuai rekening bank',
                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Pastikan data rekening benar. Dana yang sudah ditransfer tidak dapat dikembalikan jika data salah.', style: TextStyle(fontSize: 11, color: Colors.amber.shade800))),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _ajukanRefund,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.replay_outlined),
                label: Text(_isLoading ? 'Mengajukan...' : 'Ajukan Refund', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}