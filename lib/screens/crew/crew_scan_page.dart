import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crew_tiket_detail_page.dart';

class CrewScanPage extends StatefulWidget {
  const CrewScanPage({super.key});

  @override
  State<CrewScanPage> createState() =>
      _CrewScanPageState();
}

class _CrewScanPageState
    extends State<CrewScanPage> {

  final supabase =
      Supabase.instance.client;

  bool isScanned = false;

  Future<void> getTicket(
      String idTransaksi) async {

    try {

      // bersihkan hasil scan
      final cleanId = idTransaksi
          .trim()
          .replaceAll('\n', '')
          .replaceAll('\r', '');

      print("==============");
      print("HASIL SCAN:");
      print(cleanId);

      // cari transaksi
      final transaksiList =
      await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select()
          .eq(
        'id_transaksi',
        cleanId,
      );

      if (transaksiList.isEmpty) {

        throw Exception(
          "Transaksi tidak ditemukan",
        );
      }

      final trx =
          transaksiList.first;

      // ambil data event
      final event =
      await supabase
          .schema('ursaevent')
          .from('event')
          .select()
          .eq(
        'id_event',
        trx['id_event'],
      )
          .single();

      // ambil data tiket
      final tiket =
      await supabase
          .schema('ursaevent')
          .from('tikets')
          .select()
          .eq(
        'id',
        trx['id_tiket'],
      )
          .single();

      if (!mounted) return;

      // PINDAH KE HALAMAN DETAIL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CrewTiketDetailPage(
                trx: trx,
                event: event,
                tiket: tiket,
              ),
        ),
      ).then((_) {

        // aktif scan lagi saat kembali
        setState(() {
          isScanned = false;
        });

      });

    } catch(e){

      print("ERROR:");
      print(e);

      if(!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "$e",
          ),
        ),
      );

      setState(() {
        isScanned = false;
      });
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor:
        const Color(
          0xFFD32F2F,
        ),

        title: const Text(
          'Scan Tiket',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          MobileScanner(

            onDetect: (capture){

              if(isScanned) return;

              final barcode =
                  capture.barcodes.first;

              final code =
                  barcode.rawValue;

              if(code == null) return;

              setState(() {
                isScanned = true;
              });

              getTicket(code);

            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,

              decoration:
              BoxDecoration(
                border: Border.all(
                  color: Colors.red,
                  width: 3,
                ),

                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}