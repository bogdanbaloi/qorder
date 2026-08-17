import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'table_qr.dart';

/// A camera QR scanner for the table sticker. Pops with the parsed table number
/// on the first valid scan. The loyal / installed-app fast path for setting the
/// table (a normal customer's table comes from the QR link instead). The camera
/// needs a secure context (HTTPS or a native build); it is not available on a
/// plain-http LAN demo.
class QrScanScreen extends StatefulWidget {
  final String title;
  const QrScanScreen({required this.title, super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final table = tableFromScan(raw);
      if (table != null) {
        _handled = true;
        Navigator.of(context).pop(table);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
