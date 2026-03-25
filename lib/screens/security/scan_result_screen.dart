import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Future<List<Map<String, dynamic>>>? _staffFuture;

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _staffFuture = context.read<GatePassProvider>().getDepartmentStaffMembers(
        widget.request!.department ?? '',
      );
    }
  }

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

    // 1. Check Expiry (But allow return if they are already outside)
    if (req.isExpired &&
        req.status != GatePassStatus.returned &&
        req.status != GatePassStatus.exited) {
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
        final bool isLate = req.isExpired;
        return _buildResultView(
          backgroundColor: isLate ? AppColors.error : Colors.orange,
          icon: Icons.input_rounded,
          status: isLate ? "OVERDUE / OUTSIDE" : "STUDENT OUTSIDE",
          message: isLate
              ? "Student is OVERDUE but still outside. Record late return?"
              : "Student is currently outside campus. Record return?",
          showDetails: true,
          actionButton: _buildActionButton(
            isLate ? "Confirm LATE RETURN" : "Confirm RETURN",
            false,
          ),
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
                style: GoogleFonts.outfit(
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
        child: SingleChildScrollView(
          scrollDirection: .vertical,
          padding: .symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Icon(icon, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                status,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              if (showDetails && widget.request != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                      if (widget.request!.approvedByName != null)
                        _buildResultRow(
                          "Approved by",
                          "${widget.request!.approvedByName!} (${widget.request!.approvedByRole?.toUpperCase() ?? 'APPROVER'})",
                        ),
                      const Divider(color: Colors.white24, height: 32),
                      const Text(
                        "FACULTY CONTACTS",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _staffFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }
                          final staffList = snapshot.data ?? [];
                          if (staffList.isEmpty) {
                            return const Text(
                              "No staff advisors found for this department.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Column(
                            children: staffList.map((staff) {
                              final name = staff['name'] ?? 'Staff';
                              final phone = staff['phone'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                    name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    phone ?? "No phone",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: phone != null
                                      ? IconButton(
                                          onPressed: () async {
                                            final uri = Uri.parse("tel:$phone");
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.call,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.2),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (actionButton != null) actionButton,
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
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
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
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
