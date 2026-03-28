import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:smart_gate_pass/core/extensions.dart';

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

  Future<void> savePdfWithDialog() async {
    try {
      final params = SaveFileDialogParams(
        data: widget.pdfBytes,
        fileName: "${widget.title}.pdf",
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);

      if (savedPath != null) {
        context.showSnackBar('PDF saved to: $savedPath');
        context.removeCurrentSnackBar();
      } else {
        context.showSnackBar(" Save cancelled");
        context.removeCurrentSnackBar();
      }
    } catch (e) {
      log('Save error: $e');
      context.showSnackBar('Failed to save PDF: $e');
    }
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
          IconButton(
            onPressed: () => savePdfWithDialog(),
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: PdfView(controller: _pdfController, scrollDirection: Axis.vertical),
    );
  }
}
