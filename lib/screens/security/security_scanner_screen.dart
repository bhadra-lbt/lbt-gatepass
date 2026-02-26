import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/gate_pass_provider.dart';
import 'scan_result_screen.dart';

class SecurityScannerScreen extends StatefulWidget {
  const SecurityScannerScreen({super.key});

  @override
  State<SecurityScannerScreen> createState() => _SecurityScannerScreenState();
}

class _SecurityScannerScreenState extends State<SecurityScannerScreen> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gate Security Scan"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (!_isScanning) return;

                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      setState(() => _isScanning = false);
                      _handleScan(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              // Custom Overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      "Align QR Code within the frame",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text("Exit Scanner"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScan(String code) async {
    // Show a small loader or just proceed to result screen which can handle loading if needed
    // But here we'll fetch first to keep it simple
    final provider = context.read<GatePassProvider>();
    final request = await provider.getRequestById(code);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultScreen(
          passId: code,
          request: request,
          onRetry: () {
            setState(() => _isScanning = true);
          },
        ),
      ),
    );
  }
}
