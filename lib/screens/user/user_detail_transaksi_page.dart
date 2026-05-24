import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailTransaksiPage extends StatelessWidget {
  final Map<String, dynamic> trx;

  const DetailTransaksiPage({
    super.key,
    required this.trx,
  });

  Color _statusColor(String? status) {
    switch (status) {
      case 'aktif':
        return Colors.green;

      case 'refund':
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

  void _lihatGambar(
      BuildContext context,
      String url,
      String title,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme:
            const IconThemeData(
              color: Colors.white,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Center(
            child:
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child:
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buktiWidget(
      BuildContext context,
      String url,
      String title,
      ) {
    return GestureDetector(
      onTap: () {
        _lihatGambar(
          context,
          url,
          title,
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(
                10),
            child:
            CachedNetworkImage(
              imageUrl: url,
              width:
              double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.black54,
                borderRadius:
                BorderRadius.circular(
                    8),
              ),
              child: const Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [

                  Icon(
                    Icons.zoom_in,
                    size: 14,
                    color:
                    Colors.white,
                  ),

                  SizedBox(
                      width: 5),

                  Text(
                    "Tap untuk perbesar",
                    style:
                    TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {

    final event =
    trx['event']
    as Map<String,
        dynamic>?;

    final tiket =
    trx['tikets']
    as Map<String,
        dynamic>?;

    final status =
    trx['status'];

    final buktiBayar =
    trx['bukti_bayar'];

    final buktiRefund =
    trx['bukti_refund'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        const Color(
            0xFFD32F2F),

        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color:
            Colors.white,
            fontWeight:
            FontWeight
                .bold,
          ),
        ),
      ),

      backgroundColor:
      Colors.grey.shade100,

      body:
      SingleChildScrollView(

        padding:
        const EdgeInsets.all(
            16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [

            // STATUS
            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets
                  .all(16),

              decoration:
              BoxDecoration(

                color:
                _statusColor(
                    status)
                    .withOpacity(
                    .1),

                border:
                Border.all(
                  color:
                  _statusColor(
                      status),
                ),

                borderRadius:
                BorderRadius
                    .circular(
                    12),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  const Text(
                    'Status Transaksi',
                    style:
                    TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  Text(
                    status ?? "-",
                    style:
                    TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight
                          .bold,
                      color:
                      _statusColor(
                          status),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
                height: 20),

            // INFO TRANSAKSI
            Card(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius
                    .circular(
                    12),
              ),

              child: Padding(
                padding:
                const EdgeInsets
                    .all(16),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [

                    const Text(
                      'Info Transaksi',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        fontSize:
                        16,
                      ),
                    ),

                    const SizedBox(
                        height:
                        16),

                    _item(
                      'ID Transaksi',
                      trx[
                      'id_transaksi'] ??
                          '-',
                    ),

                    _item(
                      'Event',
                      event?[
                      'nama_event'] ??
                          '-',
                    ),

                    _item(
                      'Tiket',
                      '${tiket?['nama_tiket'] ?? '-'} • ${tiket?['kategori'] ?? '-'}',
                    ),

                    _item(
                      'Tanggal',
                      event?[
                      'tanggal'] ??
                          '-',
                    ),

                    _item(
                      'Total',
                      'Rp ${trx['sub_total'] ?? 0}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
                height: 20),

            // BUKTI PEMBAYARAN
            if (buktiBayar !=
                null)
              Card(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                      12),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(16),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      const Text(
                        'Bukti Pembayaran',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight
                              .bold,
                          fontSize:
                          16,
                        ),
                      ),

                      const SizedBox(
                          height:
                          15),

                      _buktiWidget(
                        context,
                        buktiBayar,
                        "Bukti Pembayaran",
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
                height: 20),

            // BUKTI REFUND
            if (status ==
                'refund' &&
                buktiRefund !=
                    null)
              Card(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                      12),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(16),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      const Text(
                        'Bukti Transfer Refund',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight
                              .bold,
                          fontSize:
                          16,
                        ),
                      ),

                      const SizedBox(
                          height:
                          15),

                      _buktiWidget(
                        context,
                        buktiRefund,
                        "Bukti Refund",
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
                height: 20),

            // QR hanya aktif
            if (status ==
                'aktif')
              Card(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                      12),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(16),

                  child: Column(
                    children: [

                      const Text(
                        'QR Tiket',
                        style:
                        TextStyle(
                          fontWeight:
                          FontWeight
                              .bold,
                          fontSize:
                          16,
                        ),
                      ),

                      const SizedBox(
                          height:
                          20),

                      QrImageView(
                        data: trx[
                        'id_transaksi'] ??
                            '',

                        version:
                        QrVersions
                            .auto,

                        size: 220,

                        backgroundColor:
                        Colors
                            .white,
                      ),

                      const SizedBox(
                          height:
                          12),

                      const Text(
                        'Tunjukkan QR ini kepada panitia saat masuk event',
                        textAlign:
                        TextAlign
                            .center,
                        style:
                        TextStyle(
                          color:
                          Colors
                              .grey,
                          fontSize:
                          12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _item(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
          bottom: 12),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [

          SizedBox(
            width: 110,
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
              value,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}