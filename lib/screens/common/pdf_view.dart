import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.title,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openData(widget.pdfBytes),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.outfit()),
        actions: [
          PdfPageNumber(
            controller: _pdfController,
            builder: (context, loadingState, page, pagesCount) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$page / ${pagesCount ?? 0}',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: PdfView(controller: _pdfController, scrollDirection: Axis.vertical),
    );
  }
}
