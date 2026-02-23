import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/gate_pass_provider.dart';

class ScanResultScreen extends StatefulWidget {
  final GatePassRequest? request;
  final String passId;
  final VoidCallback onRetry;

  const ScanResultScreen({
    super.key,
    this.request,
    required this.passId,
    required this.onRetry,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isProcessing = false;

  Future<void> _handleAction(bool isExit) async {
    if (widget.request == null) return;

    setState(() => _isProcessing = true);
    try {
      final provider = context.read<GatePassProvider>();
      if (isExit) {
        await provider.logExit(widget.request!.id);
      } else {
        await provider.logReturn(widget.request!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isExit
                  ? "Exit recorded successfully"
                  : "Return recorded successfully",
            ),
          ),
        );
        Navigator.pop(context);
        widget.onRetry();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.request == null) {
      return _buildResultView(
        backgroundColor: Colors.grey[800]!,
        icon: Icons.search_off_rounded,
        status: "NOT FOUND",
        message: "No record found for Pass ID: ${widget.passId}",
      );
    }

    final req = widget.request!;

    // 1. Check Expiry
    if (req.isExpired && req.status != GatePassStatus.returned) {
      return _buildResultView(
        backgroundColor: AppColors.error,
        icon: Icons.timer_off_outlined,
        status: "EXPIRED",
        message: "This pass has expired and is no longer valid.",
        showDetails: true,
      );
    }

    // 2. Logic based on Status
    switch (req.status) {
      case GatePassStatus.approved:
        return _buildResultView(
          backgroundColor: AppColors.success,
          icon: Icons.output_rounded,
          status: "READY FOR EXIT",
          message: "Student is authorized to exit now.",
          showDetails: true,
          actionButton: _buildActionButton("Confirm EXIT", true),
        );

      case GatePassStatus.exited:
        return _buildResultView(
          backgroundColor: Colors.orange,
          icon: Icons.input_rounded,
          status: "STUDENT OUTSIDE",
          message: "Student is currently outside campus. Record return?",
          showDetails: true,
          actionButton: _buildActionButton("Confirm RETURN", false),
        );

      case GatePassStatus.returned:
        return _buildResultView(
          backgroundColor: Colors.blue,
          icon: Icons.check_circle_rounded,
          status: "ALREADY RETURNED",
          message: "This student has already returned and the pass is closed.",
          showDetails: true,
        );

      case GatePassStatus.rejected:
        return _buildResultView(
          backgroundColor: AppColors.error,
          icon: Icons.cancel_outlined,
          status: "REJECTED",
          message: "This request was rejected by faculty.",
          showDetails: true,
        );

      case GatePassStatus.pending:
        return _buildResultView(
          backgroundColor: AppColors.warning,
          icon: Icons.pending_rounded,
          status: "PENDING",
          message: "This request is still waiting for faculty approval.",
          showDetails: true,
        );

      case GatePassStatus.expired:
        return _buildResultView(
          backgroundColor: AppColors.textSecondary,
          icon: Icons.history_rounded,
          status: "EXPIRED",
          message: "This pass has passed its validity duration.",
          showDetails: true,
        );
    }
  }

  Widget _buildActionButton(String label, bool isExit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleAction(isExit),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: isExit ? AppColors.success : Colors.orange,
          minimumSize: const Size(double.infinity, 60),
          elevation: 5,
        ),
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResultView({
    required Color backgroundColor,
    required IconData icon,
    required String status,
    required String message,
    bool showDetails = false,
    Widget? actionButton,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(icon, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              if (showDetails && widget.request != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildResultRow("Student", widget.request!.studentName),
                      _buildResultRow(
                        "Depart/Sem",
                        "${widget.request!.department ?? 'N/A'} (S${widget.request!.semester ?? '?'})",
                      ),
                      _buildResultRow(
                        "Reg No",
                        widget.request!.registerNumber ?? "N/A",
                      ),
                      _buildResultRow("Reason", widget.request!.reason),
                      _buildResultRow(
                        "Time Range",
                        "${widget.request!.fromTime} - ${widget.request!.toTime}",
                      ),
                      if (widget.request!.exitDateTime != null)
                        _buildResultRow(
                          "Exited at",
                          DateFormat(
                            'hh:mm a',
                          ).format(widget.request!.exitDateTime!),
                        ),
                      if (widget.request!.returnDateTime != null)
                        _buildResultRow(
                          "Returned at",
                          DateFormat(
                            'hh:mm a',
                          ).format(widget.request!.returnDateTime!),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              if (actionButton != null) actionButton,
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Scan Next Pass"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
