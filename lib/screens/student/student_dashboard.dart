import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'apply_pass_screen.dart';
import 'my_requests_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
      body: SingleChildScrollView(
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
            const Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.check_circle, color: AppColors.success),
                ),
                title: Text("Medical Emergency"),
                subtitle: Text("Approved by HOD"),
                trailing: Text("2h ago"),
              ),
            ),
          ],
        ),
      ),
    );
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
