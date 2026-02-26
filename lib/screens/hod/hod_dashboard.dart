import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/expandable_text.dart';
import '../profile/profile_screen.dart';

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
      _listenToRequests();
    });
  }

  void _listenToRequests() {
    if (_hodDept != null) {
      context.read<GatePassProvider>().listenToPendingRequests(
        department: _hodDept,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<GatePassProvider>();
    final pendingRequests = provider.pendingRequests;

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
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "HOD Office",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              auth.userName ?? "HOD",
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _hodDept ?? "Unknown",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${pendingRequests.length} Pending Approvals",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _listenToRequests();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: pendingRequests.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text("No pending requests found.")),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: pendingRequests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final request = pendingRequests[index];
                            return _buildApprovalCard(context, request);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
