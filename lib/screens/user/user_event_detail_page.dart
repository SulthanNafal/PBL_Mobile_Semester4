import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'user_booking_page.dart';

class UserEventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const UserEventDetailPage({super.key, required this.event});

  @override
  State<UserEventDetailPage> createState() => _UserEventDetailPageState();
}

class _UserEventDetailPageState extends State<UserEventDetailPage> {
  List<Map<String, dynamic>> _tikets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTikets();
  }

  Future<void> _fetchTikets() async {
    try {
      final data = await supabase
          .schema('ursaevent')
          .from('tikets')
          .select()
          .eq('id_event', widget.event['id_event'])
          .order('harga', ascending: true);

      setState(() {
        _tikets = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat tiket: $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'tersedia':
        return Colors.green;
      case 'belum tersedia':
        return Colors.orange;
      case 'stock habis':
        return Colors.red;
      case 'tidak tersedia':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // =========================
  // DIALOG KONFIRMASI BELI
  // =========================
  void _showBeliDialog(Map<String, dynamic> tiket) {
    int jumlah = 1;
    final int kuota = tiket['kuota'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final harga = tiket['harga'] ?? 0;
          final subtotal = harga * jumlah;

          return AlertDialog(
            title: const Text('Konfirmasi Pembelian'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text('Event: ${widget.event['nama_event']}'),
                const SizedBox(height: 4),

                Text('Tiket: ${tiket['nama_tiket']}'),
                const SizedBox(height: 4),

                Text('Kategori: ${tiket['kategori']}'),
                const SizedBox(height: 12),

                const Text(
                  'Jumlah Tiket',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    IconButton(
                      onPressed: jumlah > 1
                          ? () {
                        setStateDialog(() {
                          jumlah--;
                        });
                      }
                          : null,
                      icon: const Icon(Icons.remove_circle),
                    ),

                    Text(
                      '$jumlah',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: jumlah < kuota
                          ? () {
                        setStateDialog(() {
                          jumlah++;
                        });
                      }
                          : null,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Harga Satuan: Rp $harga',
                ),

                Text(
                  'Total: Rp $subtotal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Kamu punya 30 menit untuk menyelesaikan pembayaran.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            actions: [

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserBookingPage(
                        tiket: {
                          ...tiket,
                          'jumlah': jumlah,
                        },
                        event: widget.event,
                        jumlah: jumlah,
                      ),
                    ),
                  );
                },
                child: const Text('Lanjut Booking'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event['nama_event'] ?? 'Detail Event',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // FOTO EVENT
            // =========================
            event['foto'] != null
                ? CachedNetworkImage(
              imageUrl: event['foto'],
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
                : Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =========================
                  // INFO EVENT
                  // =========================
                  Text(
                    event['nama_event'] ?? '-',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(event['tanggal'] ?? '-', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(event['jam'] ?? '-', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['deskripsi'] ?? '-',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),

                  // =========================
                  // LIST TIKET
                  // =========================
                  const Text(
                    'Pilih Tiket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  )
                      : _tikets.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada tiket tersedia.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tikets.length,
                    itemBuilder: (context, index) {
                      final tiket = _tikets[index];
                      final status = tiket['status'] as String?;
                      final bisaBeli = status == 'tersedia';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tiket['nama_tiket'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status ?? '-',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kategori: ${tiket['kategori'] ?? '-'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                'Sisa Kuota: ${tiket['kuota'] ?? 0}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                'Penjualan: ${tiket['tanggal_mulai'] ?? '-'} s/d ${tiket['tanggal_akhir'] ?? '-'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${tiket['harga'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: bisaBeli
                                        ? () => _showBeliDialog(tiket)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD32F2F),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(bisaBeli ? 'Beli' : status ?? '-'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}