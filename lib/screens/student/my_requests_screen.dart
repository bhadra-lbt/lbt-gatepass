import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/gate_pass_provider.dart';
import 'qr_display_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GatePassProvider>();
    final requests = provider.requests;

    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: requests.isEmpty
          ? const Center(child: Text("No requests found"))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(context, request);
              },
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context, GatePassRequest request) {
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              request.reason,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
            if (request.status == GatePassStatus.approved) ...[
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
                label: const Text("Show QR Code"),
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
                style: const TextStyle(color: AppColors.error, fontSize: 13),
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
