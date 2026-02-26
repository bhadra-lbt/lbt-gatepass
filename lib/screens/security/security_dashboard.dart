import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import 'security_scanner_screen.dart';
import '../profile/profile_screen.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GatePassProvider>().listenToRecentActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<GatePassProvider>();
    final recentActivity = provider.recentActivity;

    // Filter today's stats from recentActivity
    final now = DateTime.now();
    final todayActivity = recentActivity.where((a) {
      final time = a.returnDateTime ?? a.exitDateTime;
      return time != null &&
          time.day == now.day &&
          time.month == now.month &&
          time.year == now.year;
    }).toList();

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
            context.read<GatePassProvider>().listenToRecentActivity();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildScannerButton(context),
                const SizedBox(height: 24),
                _buildStatsRow(
                  todayActivity.length.toString(),
                  todayActivity.length.toString(),
                ), // Simplified authorized count
                const SizedBox(height: 32),
                const Text(
                  "Recent Gate Activity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (recentActivity.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No recent activity recorded",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivity.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final activity = recentActivity[index];
                      return _buildActivityCard(activity);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: Icon(
            Icons.security_rounded,
            size: 80,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Gate Security Control",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Scan student QR codes to verify gate pass validity in real-time.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SecurityScannerScreen()),
        );
      },
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text("Open Scanner"),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildStatsRow(String checked, String authorized) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Checked Today",
            checked,
            Icons.people_outline,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Authorized",
            authorized,
            Icons.check_circle_outline,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(GatePassRequest activity) {
    final bool isReturn = activity.status == GatePassStatus.returned;
    final DateTime? activityTime = isReturn
        ? activity.returnDateTime
        : activity.exitDateTime;
    final String timeStr = activityTime != null
        ? DateFormat('hh:mm a').format(activityTime)
        : "N/A";

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isReturn ? Colors.blue : Colors.orange).withOpacity(
            0.1,
          ),
          child: Icon(
            isReturn ? Icons.login_rounded : Icons.logout_rounded,
            color: isReturn ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          activity.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${isReturn ? 'Returned' : 'Exited'} • S${activity.semester ?? '?'}, ${activity.department ?? 'N/A'}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              isReturn ? "IN" : "OUT",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isReturn ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
