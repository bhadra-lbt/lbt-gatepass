import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import 'apply_pass_screen.dart';
import 'my_requests_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.firebaseUser != null) {
        context.read<GatePassProvider>().listenToStudentRequests(
          auth.firebaseUser!.uid,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gatePassProvider = context.watch<GatePassProvider>();
    final recentRequest = gatePassProvider.studentRequests.isNotEmpty
        ? gatePassProvider.studentRequests.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Portal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: AppColors.secondary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            if (auth.firebaseUser != null) {
              context.read<GatePassProvider>().listenToStudentRequests(
                auth.firebaseUser!.uid,
              );
            }
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome,", style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  auth.userName ?? "Student",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                _buildActionCard(
                  context,
                  title: "Apply Gate Pass",
                  subtitle: "Request permission to leave campus",
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApplyPassScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  title: "My Requests",
                  subtitle: "Check status of your applications",
                  icon: Icons.history_edu_outlined,
                  color: AppColors.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Recent Activity",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (recentRequest != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          recentRequest.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(recentRequest.status),
                          color: _getStatusColor(recentRequest.status),
                        ),
                      ),
                      title: Text(recentRequest.reason),
                      subtitle: Text(
                        "Reg No: ${recentRequest.registerNumber ?? 'N/A'} • STATUS: ${recentRequest.status.name.toUpperCase()}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyRequestsScreen(),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No recent requests"),
                    ),
                  ),
              ],
            ),
          ),
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
      case GatePassStatus.pending:
        return AppColors.warning;
      case GatePassStatus.expired:
        return AppColors.textSecondary;
      case GatePassStatus.exited:
        return Colors.orange;
      case GatePassStatus.returned:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(GatePassStatus status) {
    switch (status) {
      case GatePassStatus.approved:
        return Icons.check_circle;
      case GatePassStatus.rejected:
        return Icons.cancel;
      case GatePassStatus.pending:
        return Icons.access_time;
      case GatePassStatus.expired:
        return Icons.history;
      case GatePassStatus.exited:
        return Icons.logout;
      case GatePassStatus.returned:
        return Icons.login;
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
