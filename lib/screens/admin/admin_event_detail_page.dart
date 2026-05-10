import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class AdminEventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const AdminEventDetailPage({super.key, required this.event});

  @override
  State<AdminEventDetailPage> createState() => _AdminEventDetailPageState();
}

class _AdminEventDetailPageState extends State<AdminEventDetailPage> {
  List<Map<String, dynamic>> _tikets = [];
  bool _isLoading = true;

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
    String status = tiket?['status'] ?? 'aktif';
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Tiket' : 'Tambah Tiket',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: namaTiketController,
                decoration: _inputDecoration('Nama Tiket'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kuotaController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Kuota'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Harga'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kategoriController,
                decoration: _inputDecoration('Kategori (VIP, Regular, dll)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: _inputDecoration('Status'),
                items: const [
                  DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                  DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                ],
                onChanged: (val) => setModalState(() => status = val!),
              ),
              const SizedBox(height: 20),
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
                      status: status,
                      isEdit: isEdit,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
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
    required String status,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .update({
          'nama_tiket': namaTiket,
          'kuota': kuota,
          'harga': harga,
          'kategori': kategori,
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', tiketId!);
      } else {
        await supabase.schema('ursaevent').from('tikets').insert({
          'id_event': widget.event['id_event'],
          'nama_tiket': namaTiket,
          'kuota': kuota,
          'harga': harga,
          'kategori': kategori,
          'status': status,
        });
      }
      await _fetchTikets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Tiket berhasil diupdate' : 'Tiket berhasil ditambah')),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTiketForm(),
        backgroundColor: const Color(0xFFD32F2F),
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
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
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
                          title: Text(
                            tiket['nama_tiket'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kategori: ${tiket['kategori'] ?? '-'}'),
                              Text('Kuota: ${tiket['kuota'] ?? 0}'),
                              Text('Harga: Rp ${tiket['harga'] ?? 0}'),
                              Text('Status: ${tiket['status'] ?? '-'}'),
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