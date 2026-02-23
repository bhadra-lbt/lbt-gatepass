import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ScanResultScreen extends StatelessWidget {
  final String passId;
  final VoidCallback onRetry;

  const ScanResultScreen({
    super.key,
    required this.passId,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Demo Logic for scan results
    final bool isValid = passId.contains("GP1");
    final bool isExpired = passId.contains("GP2");

    Color backgroundColor;
    IconData icon;
    String status;
    String message;

    if (isValid && !isExpired) {
      backgroundColor = AppColors.success;
      icon = Icons.check_circle_outline;
      status = "VALID PASS";
      message = "Student is authorized to exit.";
    } else if (isExpired) {
      backgroundColor = AppColors.warning;
      icon = Icons.history_rounded;
      status = "EXPIRED PASS";
      message = "This pass has expired. Contact HOD office.";
    } else {
      backgroundColor = AppColors.error;
      icon = Icons.cancel_outlined;
      status = "INVALID / REJECTED";
      message = "No active permission found for this ID.";
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(icon, size: 120, color: Colors.white),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildResultRow("Pass ID", passId),
                    _buildResultRow("Student", "John Doe"),
                    _buildResultRow("Time", "10:30 AM - 02:00 PM"),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text("Scan Next Pass"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  "Return to Dashboard",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
