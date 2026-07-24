import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'user_refund_page.dart';
import 'user_detail_transaksi_page.dart';
import 'user_booking_page.dart';

class UserTransaksiPage extends StatefulWidget {
  const UserTransaksiPage({super.key});

  @override
  State<UserTransaksiPage> createState() =>
      _UserTransaksiPageState();
}

class _UserTransaksiPageState
    extends State<UserTransaksiPage> {

  List<Map<String, dynamic>> _transaksi = [];
  bool _isLoading = true;

  // FILTER STATUS
  String selectedStatus = 'aktif';

  @override
  void initState() {
    super.initState();
    _fetchTransaksi();
  }

  Future<void> _fetchTransaksi() async {
    try {
      final user =
          supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('''
            *,
            event:id_event(
              nama_event,
              tanggal
            ),
            tikets:id_tiket(
              nama_tiket,
              kategori,
              harga,
              id_event
            )
          ''')
          .eq(
        'id_user',
        user.id,
      )
          .order(
        'updated_at',
        ascending: false,
      );

      setState(() {
        _transaksi =
        List<Map<String,
            dynamic>>.from(data);

        _isLoading = false;
      });

    } catch (e) {

      setState(() {
        _isLoading = false;
      });

    }
  }

  // ===============================
// HOLDING TIKET
// ===============================

  Future<void> _handleTapHolding(
      Map<String, dynamic> trx,
      ) async {

    final expiredAtStr =
    trx['expired_at']?.toString();

    if (expiredAtStr == null) return;

    final expiredAt =
    DateTime.tryParse(
        expiredAtStr);

    if (expiredAt == null) return;

    final now = DateTime.now();

    // jika waktu holding habis
    if (now.isAfter(expiredAt)) {

      try {

        // hapus transaksi
        await supabase
            .schema('ursaevent')
            .from('transaksis')
            .delete()
            .eq(
          'id_transaksi',
          trx['id_transaksi'],
        );

        // ambil kuota tiket
        final tiketData =
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .select('kuota')
            .eq(
          'id',
          trx['id_tiket'],
        )
            .single();

        final kuota =
            tiketData['kuota'] ?? 0;

        // jumlah tiket yang dipesan pada transaksi ini
        final jumlahTiket =
        (trx['jumlah'] is int)
            ? trx['jumlah'] as int
            : int.tryParse('${trx['jumlah']}') ?? 1;

        // kembalikan kuota sesuai jumlah tiket yang dipesan
        await supabase
            .schema('ursaevent')
            .from('tikets')
            .update({
          'kuota': kuota + jumlahTiket
        })
            .eq(
          'id',
          trx['id_tiket'],
        );

        if (mounted) {

          ScaffoldMessenger.of(
              context)
              .showSnackBar(

            const SnackBar(
              content: Text(
                'Transaksi holding expired dan dibatalkan otomatis',
              ),
              backgroundColor:
              Colors.red,
            ),
          );

          _fetchTransaksi();
        }

      } catch (e) {

        debugPrint(
            'ERROR HOLDING : $e'
        );

      }

      return;
    }

    // lanjutkan pembayaran

    final tiket =
        trx['tikets']
        as Map<String,dynamic>? ??
            {};

    final event =
        trx['event']
        as Map<String,dynamic>? ??
            {};

    tiket['id'] = trx['id_tiket'];
    tiket['jumlah'] = trx['jumlah'] ?? 1;

    event['id_event'] = trx['id_event'];

    if (!mounted) return;

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            UserBookingPage(
              tiket: tiket,
              event: event,
              jumlah: trx['jumlah'] ?? 1,
              existingIdTransaksi:
              trx['id_transaksi'],
              existingExpiredAt:
              expiredAt,
            ),
      ),
    );

    _fetchTransaksi();
  }

  Widget _filterButton({
    required String title,
    required String value,
  }) {

    final selected =
        selectedStatus == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus =
                value;
          });
        },

        child: Container(

          height: 36,

          margin:
          const EdgeInsets.symmetric(
            horizontal: 2,
          ),

          decoration:
          BoxDecoration(

            color: selected
                ? const Color(
                0xFFD32F2F)
                : Colors
                .grey.shade200,

            borderRadius:
            BorderRadius.circular(
                25),
          ),

          child: Center(
            child: Text(
              title,
              style:
              TextStyle(
                fontWeight:
                FontWeight
                    .bold,

                color: selected
                    ? Colors
                    .white
                    : Colors
                    .black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'aktif':
        return Colors.green;

      case 'expired':
        return Colors.grey;

      case 'refund':
        return Colors.teal;

      case 'refund diajukan':
        return Colors.teal;

      case 'cancel':
        return Colors.red;

      case 'menunggu konfirmasi':
        return Colors.orange;

      case 'holding':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(
      BuildContext context) {

    final filteredData =
    _transaksi.where((trx) {

      final status =
      trx['status']
          ?.toString()
          .toLowerCase();

      // tab refund menampilkan
      // refund + refund diajukan
      if (selectedStatus == 'refund') {

        return status == 'refund' ||
            status == 'refund diajukan';
      }

      return status == selectedStatus;

    }).toList()

      ..sort((a, b) {

        final dateA =
            DateTime.tryParse(
                a['updated_at']
                    ?.toString() ??
                    '') ??
                DateTime(2000);

        final dateB =
            DateTime.tryParse(
                b['updated_at']
                    ?.toString() ??
                    '') ??
                DateTime(2000);

        return dateB.compareTo(dateA);

      });

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color:
            Colors.white,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        backgroundColor:
        const Color(
            0xFFD32F2F),

        automaticallyImplyLeading:
        false,
      ),

      body: _isLoading

          ? const Center(
        child:
        CircularProgressIndicator(
          color: Color(
              0xFFD32F2F),
        ),
      )

          : Column(

        children: [

          const SizedBox(
              height: 15),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              16,
            ),

            child: Row(
              children: [

                _filterButton(
                  title: "Aktif",
                  value: "aktif",
                ),

                _filterButton(
                  title: "Expired",
                  value: "expired",
                ),

                _filterButton(
                  title: "Refund",
                  value: "refund",
                ),

                _filterButton(
                  title: "Cancel",
                  value: "cancel",
                ),

                _filterButton(
                  title: "Delay",
                  value: "menunggu konfirmasi",
                ),

                _filterButton(
                  title: "Holding",
                  value: "holding",
                ),

              ],
            ),
          ),

          const SizedBox(
              height: 15),

          Expanded(
            child:
            filteredData
                .isEmpty
                ? const Center(
              child:
              Text(
                "Tidak ada data",
              ),
            )

                : RefreshIndicator(
              onRefresh:
              _fetchTransaksi,

              child:
              ListView.builder(

                padding:
                const EdgeInsets
                    .all(
                    16),

                itemCount:
                filteredData
                    .length,

                itemBuilder:
                    (
                    context,
                    index,
                    ) {

                  final trx =
                  filteredData[
                  index];

                  final status =
                  trx['status'];

                  final event =
                  trx[
                  'event'];

                  final tiket =
                  trx[
                  'tikets'];

                  return InkWell(

                    onTap: () async {

                      // HOLDING
                      if (status == 'holding') {
                        await _handleTapHolding(trx);
                        return;
                      }

                      // AKTIF / REFUND / REFUND DIAJUKAN
                      if (
                      status == 'aktif' ||
                          status == 'refund' ||
                          status == 'refund diajukan'
                      ) {

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailTransaksiPage(
                              trx: trx,
                            ),
                          ),
                        );

                        _fetchTransaksi();
                      }
                    },

                    child:
                    Card(

                      margin:
                      const EdgeInsets.only(
                        bottom:
                        12,
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            12),
                      ),

                      child:
                      Padding(

                        padding:
                        const EdgeInsets.all(
                            16),

                        child:
                        Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                              children: [

                                Expanded(
                                  child:
                                  Text(
                                    trx['id_transaksi'] ??
                                        "-",

                                    overflow:
                                    TextOverflow.ellipsis,

                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal:
                                    8,
                                    vertical:
                                    4,
                                  ),

                                  decoration:
                                  BoxDecoration(
                                    color: _statusColor(status)
                                        .withOpacity(
                                        .1),

                                    borderRadius:
                                    BorderRadius.circular(
                                        6),
                                  ),

                                  child:
                                  Text(
                                    status,

                                    style:
                                    TextStyle(
                                      color:
                                      _statusColor(
                                          status),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(),

                            Text(
                              event?[
                              'nama_event'] ??
                                  "-",

                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height:
                                5),

                            Text(
                              '${tiket?['nama_tiket']} • ${tiket?['kategori']}',
                            ),

                            const SizedBox(
                                height:
                                5),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  trx['tanggal'] ?? "-",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  trx['waktu'] != null
                                      ? trx['waktu']
                                      .toString()
                                      .substring(0,5)
                                      : "-",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(height: 8),

                            Align(
                              alignment:
                              Alignment.centerRight,

                              child:
                              Text(
                                'Rp ${trx['sub_total']}',

                                style:
                                const TextStyle(
                                  color:
                                  Color(
                                      0xFFD32F2F),

                                  fontWeight:
                                  FontWeight.bold,

                                ),
                              ),
                            ),

                            // tombol refund
                            if (status == 'cancel') ...[

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,

                                child: OutlinedButton.icon(

                                  onPressed: () async {

                                    await Navigator.push(

                                      context,

                                      MaterialPageRoute(

                                        builder: (_) =>
                                            UserRefundPage(

                                              idTransaksi:
                                              trx['id_transaksi'],

                                              subTotal:
                                              trx['sub_total'],
                                            ),
                                      ),
                                    );

                                    await _fetchTransaksi();
                                  },

                                  icon: const Icon(
                                    Icons.replay_outlined,
                                  ),

                                  label: const Text(
                                    'Ajukan Refund',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  style:
                                  OutlinedButton.styleFrom(

                                    foregroundColor:
                                    Colors.teal,

                                    side: const BorderSide(
                                      color: Colors.teal,
                                    ),

                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(
                                          10),
                                    ),
                                  ),
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