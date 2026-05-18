import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../main.dart';
import 'crew_tiket_detail_page.dart';

class CrewScanPage extends StatefulWidget {
  const CrewScanPage({super.key});

  @override
  State<CrewScanPage> createState() => _CrewScanPageState();
}

class _CrewScanPageState extends State<CrewScanPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final scannedValue = barcode!.rawValue!;
    debugPrint('=== SCANNED: $scannedValue ===');

    // Validasi format URSA
    if (!scannedValue.startsWith('URSA-')) {
      _showInvalidDialog('Barcode tidak valid.\nPastikan barcode adalah tiket URSAEVENT.');
      return;
    }

    setState(() => _isProcessing = true);
    await controller.stop();

    try {
      // FETCH TRANSAKSI DARI DATABASE
      final data = await supabase
          .schema('ursaevent')
          .from('transaksis')
          .select('''
            *,
            event:id_event(nama_event, tanggal, jam, foto),
            tikets:id_tiket(nama_tiket, kategori, harga),
            users:id_user(name, username)
          ''')
          .eq('id_transaksi', scannedValue)
          .maybeSingle();

      if (data == null) {
        _showInvalidDialog('Tiket tidak ditemukan.\nID: $scannedValue');
        setState(() => _isProcessing = false);
        await controller.start();
        return;
      }

      if (!mounted) return;

      // BUKA HALAMAN DETAIL
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrewTiketDetailPage(transaksi: data),
        ),
      );

      // Reset scanner setelah kembali
      setState(() => _isProcessing = false);
      await controller.start();
    } catch (e) {
      debugPrint('ERROR SCAN: $e');
      if (mounted) {
        _showInvalidDialog('Gagal memuat data tiket.\n$e');
        setState(() => _isProcessing = false);
        await controller.start();
      }
    }
  }

  void _showInvalidDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Scan Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Tiket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // KAMERA
          MobileScanner(
            controller: controller,
            onDetect: _onBarcodeDetected,
          ),

          // OVERLAY
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // INSTRUKSI
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arahkan kamera ke barcode tiket',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Memproses...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// OVERLAY SCANNER
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanAreaSize = 280.0;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2 - 40;
    final scanRect = Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaSize, scanAreaSize);

    // Background gelap
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);

    // Border scan area
    final borderPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );

    // Sudut-sudut
    const cornerLength = 30.0;
    const cornerWidth = 4.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(scanAreaLeft, scanAreaTop + cornerLength), Offset(scanAreaLeft, scanAreaTop), cornerPaint);
    canvas.drawLine(Offset(scanAreaLeft, scanAreaTop), Offset(scanAreaLeft + cornerLength, scanAreaTop), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop), Offset(scanAreaLeft + scanAreaSize, scanAreaTop), cornerPaint);
    canvas.drawLine(Offset(scanAreaLeft + scanAreaSize, scanAreaTop), Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength), Offset(scanAreaLeft, scanAreaTop + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(scanAreaLeft, scanAreaTop + scanAreaSize), Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize), Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength), Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}