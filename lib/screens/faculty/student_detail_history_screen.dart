import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/expandable_text.dart';
import '../../services/pdf_service.dart';

class StudentDetailHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String department;
  final String semester;

  const StudentDetailHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.department,
    required this.semester,
  });

  @override
  State<StudentDetailHistoryScreen> createState() =>
      _StudentDetailHistoryScreenState();
}

class _StudentDetailHistoryScreenState
    extends State<StudentDetailHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    context.read<GatePassProvider>().listenToStudentRequests(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<GatePassProvider>().studentRequests;
    final totalOut = history
        .where(
          (e) =>
              e.status == GatePassStatus.exited ||
              e.status == GatePassStatus.returned,
        )
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Student Biography", style: GoogleFonts.outfit()),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => PdfService.exportStudentBiography(
              studentName: widget.studentName,
              registerNumber: widget.registerNumber,
              department: widget.department,
              semester: widget.semester,
              context: context,
              history: history,
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Export as PDF",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStudentHeader(totalOut),
            Expanded(
              child: history.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(history[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(int totalOut) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              widget.studentName[0].toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "${widget.registerNumber} • ${widget.department}",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Total Outings: $totalOut",
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(GatePassRequest request) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy').format(request.date),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  "${request.fromTime} - ${request.toTime}",
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                if (request.exitDateTime != null) ...[
                  const Icon(
                    Icons.logout_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(request.exitDateTime!),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
                if (request.returnDateTime != null) ...[
                  Text(" • ", style: GoogleFonts.outfit(color: Colors.grey)),
                  const Icon(Icons.login_rounded, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(request.returnDateTime!),
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ExpandableText(
              text: request.reason,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (request.approvedByName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Approved by ${request.approvedByName} (${request.approvedByRole})",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(GatePassStatus status) {
    Color color;
    String label;

    switch (status) {
      case GatePassStatus.pending:
        color = AppColors.warning;
        label = "Pending";
        break;
      case GatePassStatus.approved:
        color = AppColors.success;
        label = "Approved";
        break;
      case GatePassStatus.rejected:
        color = AppColors.error;
        label = "Rejected";
        break;
      case GatePassStatus.exited:
        color = Colors.orange;
        label = "Outside";
        break;
      case GatePassStatus.returned:
        color = Colors.blue;
        label = "Returned";
        break;
      case GatePassStatus.expired:
        color = Colors.grey;
        label = "Expired";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No gate pass history found."));
  }
}
