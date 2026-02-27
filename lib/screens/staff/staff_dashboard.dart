import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/expandable_text.dart';
import '../profile/profile_screen.dart';
import '../faculty/faculty_history_screen.dart';
import 'package:intl/intl.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  String? _dept;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _dept = auth.userProfile?['department'];
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    if (_dept != null) {
      final provider = context.read<GatePassProvider>();
      provider.listenToPendingRequests(department: _dept);
      provider.listenToFilteredActivity(department: _dept);
      provider.listenToOverdueRequests(department: _dept);
      provider.listenToActiveOutsideRequests(department: _dept);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<GatePassProvider>();
    final pendingRequests = provider.pendingRequests;
    final overdueRequests = provider.overdueRequests;
    final recentHistory = provider.filteredActivity.take(3).toList();

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
              // 1. Stats and History Link
              _buildControlCard(
                context,
                pendingCount: pendingRequests.length,
                outsideCount: provider.activeOutsideRequests.length,
                overdueCount: overdueRequests.length,
              ),

              const SizedBox(height: 24),

              // 2. Overdue Section (Urgent)
              if (overdueRequests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pendingRequests.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${pendingRequests.length} Tasks",
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

              const SizedBox(height: 8),

              // 4. Recent Activity Section (History Summary)
              if (recentHistory.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
          if (_dept != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyHistoryScreen(department: _dept!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.school_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Advisor Dashboard",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _dept ?? "Department",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: null, // Click handled by parent InkWell
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      "HISTORY",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(
                      "Pending",
                      "$pendingCount",
                      Icons.pending_actions_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickStat(
                      "Outside",
                      "$outsideCount",
                      Icons.logout_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickStat(
                      "Overdue",
                      "$overdueCount",
                      Icons.timer_off_outlined,
                      isUrgent: overdueCount > 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String val,
    IconData icon, {
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard(GatePassRequest request) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.error.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.error, size: 20),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Expected back by ${request.toTime}",
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.warning,
            color: AppColors.error.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTile(GatePassRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_pin_circle_outlined,
                color: _getStatusColor(request.status),
                size: 20,
              ),
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${DateFormat('dd MMM').format(request.date)} • ${request.status.name.toUpperCase()}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Reg. No: ${request.registerNumber}\nS${request.semester ?? '?'} ${request.department ?? 'N/A'}",
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  request.id,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              "Reason:",
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ExpandableText(
              text: request.reason,
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text("${request.fromTime} - ${request.toTime}"),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectionDialog(context, request.id),
                    style: OutlinedButton.styleFrom(
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
                      backgroundColor: AppColors.success,
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
