import 'package:flutter/material.dart';
import '../../main.dart';
import 'finance_transaksi_detail_page.dart';

class FinanceTransaksiPage extends StatefulWidget {
  const FinanceTransaksiPage({super.key});

  @override
  State<FinanceTransaksiPage> createState() => _FinanceTransaksiPageState();
}

class _FinanceTransaksiPageState extends State<FinanceTransaksiPage> {
  List<Map<String, dynamic>> _transaksi = [];
  bool _isLoading = true;

  static const _red = Color(0xFFD32F2F);

  // Filter tombol (Cancel → Expired)
  String selectedStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _fetchTransaksi();
  }

  Future<void> _fetchTransaksi() async {
    try {
      final data = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('''
            *,
            event:id_event(nama_event, tanggal, foto),
            tikets:id_tiket(nama_tiket, kategori, harga)
          ''')
          .order('tanggal', ascending: false);

      setState(() {
        _transaksi = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransaksi {
    if (selectedStatus == 'semua') return _transaksi;
    final Map<String, List<String>> filterMap = {
      'menunggu': ['menunggu konfirmasi'],
      'aktif': ['aktif'],
      'refund': ['refund', 'refund diajukan'],
      'expired': ['expired', 'cancel'], // expired mencakup status lama "cancel"
    };
    final statuses = filterMap[selectedStatus] ?? [];
    return _transaksi.where((t) => statuses.contains(t['status'])).toList();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'holding':
        return Colors.purple;
      case 'menunggu konfirmasi':
        return Colors.orange;
      case 'dikonfirmasi':
        return Colors.blue;
      case 'aktif':
        return Colors.green;
      case 'cancel':
      case 'expired':
        return Colors.red;
      case 'refund':
      case 'refund diajukan':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'holding':
        return Icons.timer_outlined;
      case 'menunggu konfirmasi':
        return Icons.hourglass_empty_outlined;
      case 'dikonfirmasi':
        return Icons.check_circle_outline;
      case 'aktif':
        return Icons.confirmation_number_outlined;
      case 'cancel':
      case 'expired':
        return Icons.cancel_outlined;
      case 'refund':
      case 'refund diajukan':
        return Icons.replay_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final num value =
    amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    )}';
  }

  // Tombol filter seperti user
  Widget _filterButton({
    required String title,
    required String value,
  }) {
    final selected = selectedStatus == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = value;
          });
        },
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? _red : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTransaksi;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _red,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : Column(
        children: [
          const SizedBox(height: 15),

          // Filter tombol-tombol seperti user
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterButton(title: 'Semua', value: 'semua'),
                _filterButton(title: 'Menunggu', value: 'menunggu'),
                _filterButton(title: 'Aktif', value: 'aktif'),
                _filterButton(title: 'Refund', value: 'refund'),
                _filterButton(title: 'Expired', value: 'expired'),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: list.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada transaksi',
                    style:
                    TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: _red,
              onRefresh: _fetchTransaksi,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final trx = list[index];
                  final status = trx['status'] as String?;
                  final event =
                  trx['event'] as Map<String, dynamic>?;
                  final tiket =
                  trx['tikets'] as Map<String, dynamic>?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FinanceTransaksiDetailPage(
                                    transaksi: trx),
                          ),
                        );
                        _fetchTransaksi();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    trx['id_transaksi'] ?? '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(status),
                                          size: 12,
                                          color:
                                          _statusColor(status)),
                                      const SizedBox(width: 4),
                                      Text(
                                        status ?? '-',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                            _statusColor(status),
                                            fontWeight:
                                            FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              event?['nama_event'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(event?['tanggal'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatRupiah(trx['sub_total']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _red,
                                      fontSize: 14),
                                ),
                                if (trx['bukti_bayar'] != null)
                                  Row(
                                    children: [
                                      Icon(Icons.image_outlined,
                                          size: 14,
                                          color:
                                          Colors.green.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ada bukti bayar',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .green.shade600,
                                            fontWeight:
                                            FontWeight.w500),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (status == 'menunggu konfirmasi') ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                      Colors.orange.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons.touch_app_outlined,
                                        size: 14,
                                        color:
                                        Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap untuk konfirmasi pembayaran',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                          Colors.orange.shade700,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (status == 'refund diajukan') ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.teal.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.replay_outlined,
                                        size: 14,
                                        color:
                                        Colors.teal.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'User mengajukan refund',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                          Colors.teal.shade700,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}