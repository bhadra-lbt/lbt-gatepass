import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import 'qr_display_screen.dart';
import '../../widgets/expandable_text.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GatePassProvider>();
    final requests = provider.studentRequests;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text("My Requests")),
        body: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            if (auth.firebaseUser != null) {
              context.read<GatePassProvider>().listenToStudentRequests(
                auth.firebaseUser!.uid,
              );
            }
            await Future.delayed(const Duration(seconds: 1));
          },
          child: requests.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text("No requests found")),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(context, request);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, GatePassRequest request) {
    // Show QR code for both Approved (to exit) and Exited (to return)
    final bool canShowQR =
        request.status == GatePassStatus.approved ||
        request.status == GatePassStatus.exited;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.id,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 16),
            ExpandableText(
              text: request.reason,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Register Number: ${request.registerNumber ?? 'Not provided'}",
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(request.date)),
                const SizedBox(width: 24),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text("${request.fromTime} - ${request.toTime}"),
              ],
            ),
            if (canShowQR) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRDisplayScreen(request: request),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  request.status == GatePassStatus.exited
                      ? "Show QR to Return"
                      : "Show QR Code",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
            if (request.status == GatePassStatus.rejected) ...[
              const SizedBox(height: 12),
              Text(
                "Reason: ${request.rejectionReason ?? 'Standard policy'}",
                style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13),
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
      case GatePassStatus.expired:
        color = AppColors.textSecondary;
        label = "Expired";
        break;
      case GatePassStatus.exited:
        color = Colors.orange;
        label = "Outside";
        break;
      case GatePassStatus.returned:
        color = Colors.blue;
        label = "Returned";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
