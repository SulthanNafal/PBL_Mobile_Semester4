import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';

class UserUploadBuktiPage extends StatefulWidget {
  final String idTransaksi;
  final Map<String, dynamic> tiket;
  final Map<String, dynamic> event;
  final int jumlah;
  final Timer? timer;


  const UserUploadBuktiPage({
    super.key,
    required this.idTransaksi,
    required this.tiket,
    required this.event,
    required this.timer,
    required this.jumlah,
  });

  @override
  State<UserUploadBuktiPage> createState() => _UserUploadBuktiPageState();
}

class _UserUploadBuktiPageState extends State<UserUploadBuktiPage> {
  File? _imageBukti;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imageBukti = File(picked.path));
    }
  }

  Future<void> _uploadBukti() async {
    if (_imageBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto bukti bayar dulu!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileName =
          'bukti_${widget.idTransaksi}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _imageBukti!.readAsBytes();

      await supabase.storage.from('bukti-bayar').uploadBinary(fileName, bytes);

      final urlBukti =
      supabase.storage.from('bukti-bayar').getPublicUrl(fileName);

      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .update({
        'bukti_bayar': urlBukti,
        'status': 'menunggu konfirmasi',
      })
          .eq('id_transaksi', widget.idTransaksi);

      widget.timer?.cancel();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Pembayaran Terkirim!'),
            content: const Text(
              'Bukti pembayaran berhasil dikirim.\nTiket akan dikirim setelah pembayaran dikonfirmasi oleh tim kami.',
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
                child: const Text('Lihat Transaksi'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload bukti: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Bukti Bayar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // RINGKASAN PESANAN
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
                    'Ringkasan Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${widget.idTransaksi}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Event: ${widget.event['nama_event']}',
                  ),

                  Text(
                    'Tiket: ${widget.tiket['nama_tiket']} - ${widget.tiket['kategori']}',
                  ),

                  Text(
                    'Jumlah: ${widget.jumlah} Tiket',
                  ),

                  Text(
                    'Total: Rp ${widget.tiket['harga']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Foto Bukti Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // AREA UPLOAD FOTO
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageBukti != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageBukti!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Tap untuk pilih foto',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'JPG, PNG maksimal 5MB',
                      style:
                      TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            if (_imageBukti != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Ganti Foto'),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadBukti,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isUploading ? 'Mengupload...' : 'Kirim Bukti Pembayaran',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}