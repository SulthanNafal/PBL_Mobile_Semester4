import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailTransaksiPage extends StatelessWidget {
  final Map<String, dynamic> trx;

  const DetailTransaksiPage({
    super.key,
    required this.trx,
  });

  @override
  Widget build(BuildContext context) {
    final event = trx['event'] as Map<String, dynamic>?;
    final tiket = trx['tikets'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // INFO TRANSAKSI
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Info Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _item(
                      'ID Transaksi',
                      trx['id_transaksi'] ?? '-',
                    ),

                    _item(
                      'Event',
                      event?['nama_event'] ?? '-',
                    ),

                    _item(
                      'Tiket',
                      '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}',
                    ),

                    _item(
                      'Jumlah',
                      '${trx['jumlah'] ?? 1} Tiket',
                    ),

                    _item(
                      'Tanggal',
                      event?['tanggal'] ?? '-',
                    ),

                    _item(
                      'Total',
                      'Rp ${trx['sub_total'] ?? 0}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QR TIKET
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    const Text(
                      'QR Tiket',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    QrImageView(
                      data: trx['id_transaksi'] ?? '',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Tunjukkan QR ini kepada panitia saat masuk event',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}