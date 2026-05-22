import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class SuperadminTiketPage extends StatefulWidget {
  final Map<String, dynamic> event;
  const SuperadminTiketPage({super.key, required this.event});

  @override
  State<SuperadminTiketPage> createState() => _SuperadminTiketPageState();
}

class _SuperadminTiketPageState extends State<SuperadminTiketPage> {
  List<Map<String, dynamic>> _tikets = [];
  bool _isLoading = true;

  static const _purple = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _fetchTikets();
  }

  // =========================
  // FETCH TIKETS
  // =========================
  Future<void> _fetchTikets() async {
    try {
      final data = await supabase
          .schema('ursaevent')
          .from('tikets')
          .select()
          .eq('id_event', widget.event['id_event'])
          .order('created_at', ascending: true);

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

  // =========================
  // TAMBAH / EDIT TIKET
  // =========================
  void _showTiketForm({Map<String, dynamic>? tiket}) {
    final namaTiketController = TextEditingController(text: tiket?['nama_tiket']);
    final kuotaController = TextEditingController(text: tiket?['kuota']?.toString());
    final hargaController = TextEditingController(text: tiket?['harga']?.toString());
    final kategoriController = TextEditingController(text: tiket?['kategori']);
    DateTime? tanggalMulai = tiket?['tanggal_mulai'] != null
        ? DateTime.tryParse(tiket!['tanggal_mulai'])
        : null;
    DateTime? tanggalAkhir = tiket?['tanggal_akhir'] != null
        ? DateTime.tryParse(tiket!['tanggal_akhir'])
        : null;
    final isEdit = tiket != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Tiket' : 'Tambah Tiket',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // NAMA TIKET
                TextField(
                  controller: namaTiketController,
                  decoration: _inputDecoration('Nama Tiket'),
                ),
                const SizedBox(height: 12),

                // KUOTA
                TextField(
                  controller: kuotaController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Kuota'),
                ),
                const SizedBox(height: 12),

                // HARGA
                TextField(
                  controller: hargaController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Harga'),
                ),
                const SizedBox(height: 12),

                // KATEGORI
                TextField(
                  controller: kategoriController,
                  decoration: _inputDecoration('Kategori (VIP, Reguler, dll)'),
                ),
                const SizedBox(height: 12),

                // TANGGAL MULAI
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tanggalMulai ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setModalState(() => tanggalMulai = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          tanggalMulai != null
                              ? 'Mulai: ${tanggalMulai!.toLocal().toString().split(' ')[0]}'
                              : 'Tanggal Mulai Penjualan',
                          style: TextStyle(
                            color: tanggalMulai != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TANGGAL AKHIR
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tanggalAkhir ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setModalState(() => tanggalAkhir = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          tanggalAkhir != null
                              ? 'Akhir: ${tanggalAkhir!.toLocal().toString().split(' ')[0]}'
                              : 'Tanggal Akhir Penjualan',
                          style: TextStyle(
                            color: tanggalAkhir != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // INFO STATUS OTOMATIS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: _purple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status tiket otomatis diatur berdasarkan tanggal dan kuota.',
                          style: TextStyle(fontSize: 12, color: _purple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // TOMBOL SIMPAN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveTiket(
                        tiketId: tiket?['id'],
                        namaTiket: namaTiketController.text.trim(),
                        kuota: int.tryParse(kuotaController.text.trim()) ?? 0,
                        harga: double.tryParse(hargaController.text.trim()) ?? 0,
                        kategori: kategoriController.text.trim(),
                        tanggalMulai: tanggalMulai,
                        tanggalAkhir: tanggalAkhir,
                        isEdit: isEdit,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Tiket',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // SAVE TIKET (TAMBAH/EDIT)
  // =========================
  Future<void> _saveTiket({
    int? tiketId,
    required String namaTiket,
    required int kuota,
    required double harga,
    required String kategori,
    DateTime? tanggalMulai,
    DateTime? tanggalAkhir,
    required bool isEdit,
  }) async {
    try {
      final payload = {
        'nama_tiket': namaTiket,
        'kuota': kuota,
        'harga': harga,
        'kategori': kategori,
        'tanggal_mulai': tanggalMulai?.toIso8601String().split('T')[0],
        'tanggal_akhir': tanggalAkhir?.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEdit) {
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .update(payload)
            .eq('id', tiketId!);
      } else {
        payload['id_event'] = widget.event['id_event'];
        await supabase.schema('ursaevent').from('tikets').insert(payload);
      }

      await _fetchTikets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Tiket berhasil diupdate' : 'Tiket berhasil ditambah'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tiket: $e')),
        );
      }
    }
  }

  // =========================
  // HAPUS TIKET
  // =========================
  Future<void> _deleteTiket(int tiketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tiket'),
        content: const Text('Yakin ingin menghapus tiket ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .delete()
            .eq('id', tiketId);
        await _fetchTikets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tiket berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus tiket: $e')),
          );
        }
      }
    }
  }

  // =========================
  // WARNA STATUS
  // =========================
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _purple, width: 2),
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
        backgroundColor: _purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTiketForm(),
        backgroundColor: _purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Tiket', style: TextStyle(color: Colors.white)),
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

            // =========================
            // INFO EVENT
            // =========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  // SECTION TIKET
                  // =========================
                  const Text(
                    'Manajemen Tiket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(color: _purple),
                  )
                      : _tikets.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada tiket.\nTambah tiket dengan tombol di bawah.',
                        textAlign: TextAlign.center,
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tiket['nama_tiket'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kategori: ${tiket['kategori'] ?? '-'}'),
                              Text('Kuota: ${tiket['kuota'] ?? 0}'),
                              Text('Harga: Rp ${tiket['harga'] ?? 0}'),
                              Text('Mulai: ${tiket['tanggal_mulai'] ?? '-'}'),
                              Text('Akhir: ${tiket['tanggal_akhir'] ?? '-'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _showTiketForm(tiket: tiket),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteTiket(tiket['id']),
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