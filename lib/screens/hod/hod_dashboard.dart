import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/expandable_text.dart';
import '../profile/profile_screen.dart';
import '../faculty/faculty_history_screen.dart';

class HODDashboard extends StatefulWidget {
  const HODDashboard({super.key});

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard> {
  String? _hodDept;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _hodDept = auth.userProfile?['department'];
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    if (_hodDept != null) {
      final provider = context.read<GatePassProvider>();
      provider.listenToPendingRequests(department: _hodDept);
      provider.listenToFilteredActivity(department: _hodDept);
      provider.listenToOverdueRequests(department: _hodDept);
      provider.listenToActiveOutsideRequests(department: _hodDept);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<GatePassProvider>();
    final pendingRequests = provider.pendingRequests;
    final overdueRequests = provider.overdueRequests;
    final recentHistory = provider.filteredActivity.take(4).toList();

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('asset/playstore.png'),
          ),
          title: const Text("LBT Smart Pass"),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _fetchInitialData();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // 1. Header Card with Stats and History Link
              _buildControlCard(
                context,
                pendingCount: pendingRequests.length,
                outsideCount: provider.activeOutsideRequests.length,
                overdueCount: overdueRequests.length,
              ),

              const SizedBox(height: 32),

              // 2. Overdue Section (Urgent)
              if (overdueRequests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Currently Overdue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...overdueRequests.map(
                  (req) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _buildOverdueCard(req),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Pending Requests Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pending Approvals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pendingRequests.isNotEmpty)
                      Chip(
                        label: Text(
                          "${pendingRequests.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (pendingRequests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("All caught up! No pending requests."),
                  ),
                )
              else
                ...pendingRequests.map(
                  (req) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildApprovalCard(context, req),
                  ),
                ),

              const SizedBox(height: 16),

              // 4. Recent History Section
              if (recentHistory.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Recent Activities",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ...recentHistory.map((req) => _buildRecentActivityTile(req)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard(
    BuildContext context, {
    required int pendingCount,
    required int outsideCount,
    required int overdueCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          if (_hodDept != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyHistoryScreen(department: _hodDept!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: ClipRRect(
          // 1. Necessary to keep the blur inside the card corners
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            // 2. Blurs what is BEHIND the card
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "HOD Office",
                              style: TextStyle(color: AppColors.primary),
                            ),
                            Text(
                              _hodDept ?? "Unknown Dept",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: null, // Entire card is clickable
                        icon: const Icon(
                          Icons.history_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        label: const Text(
                          "HISTORY",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem("Action", "$pendingCount"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatItem("Out", "$outsideCount")),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatItem(
                          "Late",
                          "$overdueCount",
                          isUrgent: overdueCount > 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String val, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: isUrgent ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isUrgent ? Colors.white : AppColors.primary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard(GatePassRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: .4)),
      ),
      child: ClipRRect(
        // 1. Necessary to keep the blur inside the card corners
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          // 2. Blurs what is BEHIND the card
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background.withOpacity(
              0.08,
            ), // 3. Translucent color
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.error),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        "S${request.semester} • Due: ${request.toTime}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.error,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityTile(GatePassRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: ListTile(
        onTap: () {
          // Could open details modal
        },
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
          child: Icon(
            Icons.person_outline,
            color: _getStatusColor(request.status),
            size: 20,
          ),
        ),
        title: Text(
          request.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "${DateFormat('dd MMM').format(request.date)} • ${request.status.name}",
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  Color _getStatusColor(GatePassStatus status) {
    switch (status) {
      case GatePassStatus.approved:
        return AppColors.success;
      case GatePassStatus.rejected:
        return AppColors.error;
      case GatePassStatus.exited:
        return Colors.orange;
      case GatePassStatus.returned:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildApprovalCard(BuildContext context, GatePassRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Reg. No: ${request.registerNumber}\nS${request.semester ?? '?'} ${request.department ?? 'N/A'}",
                        style: GoogleFonts.roboto(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  request.id,
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Text(
              "Requested Reason:",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ExpandableText(
              text: request.reason,
              style: GoogleFonts.outfit(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.alarm, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  "${request.fromTime} to ${request.toTime}",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectionDialog(context, request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<GatePassProvider>().updateStatus(
                        request.id,
                        GatePassStatus.approved,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, String requestId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please provide a reason for rejecting this gate pass request.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter rejection reason...",
                border: OutlineInputBorder(),
                fillColor: AppColors.background,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reason is required")),
                );
                return;
              }
              context.read<GatePassProvider>().updateStatus(
                requestId,
                GatePassStatus.rejected,
                reason: controller.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }
}
