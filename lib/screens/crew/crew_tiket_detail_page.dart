import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrewTiketDetailPage extends StatefulWidget {
  final Map<String, dynamic> trx;
  final Map<String, dynamic> event;
  final Map<String, dynamic> tiket;

  const CrewTiketDetailPage({
    super.key,
    required this.trx,
    required this.event,
    required this.tiket,
  });

  @override
  State<CrewTiketDetailPage> createState() =>
      _CrewTiketDetailPageState();
}

class _CrewTiketDetailPageState
    extends State<CrewTiketDetailPage> {

  final supabase =
      Supabase.instance.client;

  bool isLoading = false;

  // status tiket saat halaman dibuka (dari hasil scan)
  late String _status;

  bool get _sudahTerpakai =>
      _status == 'expired';

  @override
  void initState() {
    super.initState();

    _status =
        widget.trx['status']?.toString() ?? '';

    // kalau tiket sudah expired (sudah terpakai) saat pertama dibuka,
    // langsung tampilkan popup peringatan
    if (_sudahTerpakai) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        _showSudahTerpakaiDialog();
      });
    }
  }

  // =========================
  // POPUP TIKET SUDAH TERPAKAI
  // =========================
  void _showSudahTerpakaiDialog() {

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (_) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(15),
          ),

          title: const Row(
            children: [

              Icon(
                Icons.error_outline,
                color: Colors.red,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Tiket Sudah Terpakai",
                ),
              ),
            ],
          ),

          content: const Text(
            "Tiket ini sudah pernah digunakan (check-in) sebelumnya "
                "dan tidak dapat digunakan lagi.",
          ),

          actions: [

            ElevatedButton(

              onPressed: () {

                // tutup popup
                Navigator.pop(context);

              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  Future<void> acceptTicket() async {

    try {

      setState(() {
        isLoading = true;
      });

      // CEK ULANG STATUS TERBARU DARI DATABASE
      // (mencegah tiket yang sama di-checkin 2x oleh crew berbeda
      // secara bersamaan)
      final latest = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('status')
          .eq(
        'id_transaksi',
        widget.trx['id_transaksi'],
      )
          .single();

      final latestStatus =
          latest['status']?.toString() ?? '';

      if (latestStatus == 'expired') {

        if (!mounted) return;

        setState(() {
          _status = latestStatus;
          isLoading = false;
        });

        _showSudahTerpakaiDialog();
        return;
      }

      // update status tiket
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .update({

        'status': 'expired',

      })
          .eq(
        'id_transaksi',
        widget.trx['id_transaksi'],
      );

      if (!mounted) return;

      setState(() {
        _status = 'expired';
      });

      // popup berhasil
      showDialog(
        context: context,
        barrierDismissible: false,

        builder: (_) {

          return AlertDialog(

            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),

            title: const Row(
              children: [

                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

                SizedBox(width: 10),

                Text(
                  "Check-in Berhasil",
                ),
              ],
            ),

            content: const Text(
              "Tiket telah digunakan dan status berubah menjadi expired",
            ),

            actions: [

              ElevatedButton(

                onPressed: () {

                  // tutup popup
                  Navigator.pop(
                    context,
                  );

                  // kembali ke scanner
                  Navigator.pop(
                    context,
                  );

                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.green,

                  foregroundColor:
                  Colors.white,
                ),

                child: const Text(
                  "OK",
                ),
              )
            ],
          );
        },
      );

    } catch(e){

      showDialog(
        context: context,

        builder: (_) {

          return AlertDialog(

            title: const Text(
              "Error",
            ),

            content: Text(
              "$e",
            ),

            actions: [

              TextButton(
                onPressed: () {

                  Navigator.pop(
                    context,
                  );

                },

                child: const Text(
                  "OK",
                ),
              )
            ],
          );
        },
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor:
        const Color(0xFFD32F2F),

        title: const Text(
          "Detail Tiket",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          children: [

            Card(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),

              child: Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Info Tiket",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _item(
                      "ID",
                      widget.trx[
                      'id_transaksi'],
                    ),

                    _item(
                      "Event",
                      widget.event[
                      'nama_event'],
                    ),

                    _item(
                      "Tiket",
                      widget.tiket[
                      'nama_tiket'],
                    ),

                    _item(
                      "Kategori",
                      widget.tiket[
                      'kategori'],
                    ),

                    _item(
                      "Jumlah Tiket",
                      "${widget.trx['jumlah'] ?? 1}",
                    ),

                    _item(
                      "Tanggal",
                      widget.event[
                      'tanggal']
                          .toString(),
                    ),

                    _item(
                      "Total",
                      "Rp ${widget.trx['sub_total']}",
                    ),

                    _item(
                      "Status",
                      _status,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [

                Expanded(
                  child:
                  ElevatedButton.icon(

                    onPressed: () {

                      Navigator.pop(
                        context,
                      );

                    },

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.grey,

                      foregroundColor:
                      Colors.white,
                    ),

                    icon:
                    const Icon(
                      Icons.qr_code_scanner,
                    ),

                    label:
                    const Text(
                      "Scan Lagi",
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                  ElevatedButton.icon(

                    onPressed:
                    (isLoading || _sudahTerpakai)
                        ? null
                        : acceptTicket,

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      _sudahTerpakai
                          ? Colors.grey
                          : Colors.green,

                      foregroundColor:
                      Colors.white,
                    ),

                    icon:
                    isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : Icon(
                      _sudahTerpakai
                          ? Icons.block
                          : Icons.check,
                    ),

                    label:
                    Text(
                      _sudahTerpakai
                          ? "Sudah Terpakai"
                          : "Accept",
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _item(
      String title,
      dynamic value){

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 15,
      ),

      child: Row(
        children: [

          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
              const TextStyle(
                color:
                Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value.toString(),
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }
}