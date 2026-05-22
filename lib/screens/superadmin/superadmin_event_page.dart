import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'superadmin_tiket_page.dart';

class SuperadminEventPage extends StatefulWidget {
  const SuperadminEventPage({super.key});

  @override
  State<SuperadminEventPage> createState() => _SuperadminEventPageState();
}

class _SuperadminEventPageState extends State<SuperadminEventPage> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final data = await supabase
          .schema('ursaevent')
          .from('event')
          .select()
          .order('tanggal', ascending: true);

      setState(() {
        _events = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Event',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _events.isEmpty
          ? const Center(child: Text('Belum ada event'))
          : RefreshIndicator(
        color: const Color(0xFFD32F2F),
        onRefresh: _fetchEvents,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _events.length,
          itemBuilder: (context, index) =>
              _buildEventCard(_events[index]),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuperadminTiketPage(event: event),
            ),
          ).then((_) => _fetchEvents());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              child: event['foto'] != null
                  ? CachedNetworkImage(
                imageUrl: event['foto'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              )
                  : Container(
                height: 160,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['nama_event'] ?? '-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(event['tanggal'] ?? '-',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(event['jam'] ?? '-',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event['status'] == 'aktif'
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event['status'] ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: event['status'] == 'aktif'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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