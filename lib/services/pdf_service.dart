import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/gate_pass.dart';
import '../screens/common/pdf_preview_screen.dart' show PdfPreviewScreen;

class PdfService {
  static Future<void> exportStudentBiography({
    required String studentName,
    required String registerNumber,
    required String department,
    required String semester,
    required List<GatePassRequest> history,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader("STUDENT GATE PASS BIOGRAPHY"),
            pw.SizedBox(height: 20),
            _buildStudentInfo(
              studentName,
              registerNumber,
              department,
              semester,
            ),
            pw.SizedBox(height: 20),
            _buildStats(history),
            pw.SizedBox(height: 20),
            pw.Text(
              "Gate Pass History",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildHistoryTable(history),
          ];
        },
      ),
    );

    pdf.save().then((value) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfBytes: value,
              title: "$studentName GP History",
            ),
          ),
        );
      }
    });
  }

  static Future<void> exportDepartmentReport({
    required String department,
    required List<GatePassRequest> history,
    DateTime? date,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : "All Time";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader("GATE PASS ACTIVITY REPORT - $department"),
            pw.SizedBox(height: 10),
            pw.Text(
              "Report Date: $dateStr",
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            _buildHistoryTable(history, showStudentName: true),
          ];
        },
      ),
    );

    // await Printing.layoutPdf(
    //   onLayout: (PdfPageFormat format) async => pdf.save(),
    //   name: '${department}_report_${date?.millisecondsSinceEpoch ?? "all"}.pdf',
    // );
    pdf.save().then((value) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PdfPreviewScreen(pdfBytes: value, title: "Student Biography"),
          ),
        );
      }
    });
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Container(
          height: 2,
          color: PdfColors.blue900,
          width: double.infinity,
        ),
      ],
    );
  }

  static pw.Widget _buildStudentInfo(
    String name,
    String reg,
    String dept,
    String sem,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [_infoRow("Name:", name), _infoRow("Reg. No:", reg)],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow("Department:", dept),
              _infoRow("Semester:", "S$sem"),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: "$label ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildStats(List<GatePassRequest> history) {
    final total = history.length;
    final approved = history
        .where(
          (e) =>
              e.status == GatePassStatus.approved ||
              e.status == GatePassStatus.exited ||
              e.status == GatePassStatus.returned,
        )
        .length;
    final rejected = history
        .where((e) => e.status == GatePassStatus.rejected)
        .length;

    return pw.Row(
      children: [
        _statBox("Total Requests", total.toString()),
        pw.SizedBox(width: 10),
        _statBox("Approved", approved.toString(), color: PdfColors.green900),
        pw.SizedBox(width: 10),
        _statBox("Rejected", rejected.toString(), color: PdfColors.red900),
      ],
    );
  }

  static pw.Widget _statBox(
    String label,
    String value, {
    PdfColor color = PdfColors.black,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: PdfColors.grey100),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHistoryTable(
    List<GatePassRequest> history, {
    bool showStudentName = false,
  }) {
    final headers = [
      if (showStudentName) 'Student',
      'Date',
      'From',
      'To',
      'Reason',
      'Status',
      'Exit',
      'Return',
      'Approved By',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: history.map((e) {
        return [
          if (showStudentName) e.studentName,
          DateFormat('dd MMM yyyy').format(e.date),
          (e.fromTime),
          e.toTime,
          e.reason,
          e.status.name.toUpperCase(),
          (e.exitDateTime != null
              ? DateFormat('hh:mm a').format(e.exitDateTime!)
              : "-"),
          (e.returnDateTime != null
              ? DateFormat('hh:mm a').format(e.returnDateTime!)
              : "-"),
          e.approvedByName ?? "-",
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: pw.TextStyle(fontSize: 10, color: PdfColors.black),
      cellHeight: 30,
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
      },
    );
  }
}
