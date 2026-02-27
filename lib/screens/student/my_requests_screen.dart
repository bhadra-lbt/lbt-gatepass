import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import 'qr_display_screen.dart';
import '../../widgets/expandable_text.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  DateTime? _selectedDate;
  GatePassStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  void _onRefresh(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.firebaseUser != null) {
      context.read<GatePassProvider>().listenToStudentRequests(
        auth.firebaseUser!.uid,
        date: _selectedDate,
        status: _selectedStatus,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GatePassProvider>();
    var requests = provider.studentRequests;

    // Local Search Filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      requests = requests.where((req) {
        return req.id.toLowerCase().contains(query) ||
            req.reason.toLowerCase().contains(query);
      }).toList();
    }

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Requests"),
          actions: [
            IconButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,

                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(DateTime.now().year, 1, 1),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _onRefresh(context);
                }
              },
              icon: Icon(
                _selectedDate == null
                    ? Icons.calendar_month_outlined
                    : Icons.calendar_month,
                color: _selectedDate == null ? null : AppColors.primary,
              ),
            ),
            if (_selectedDate != null ||
                _selectedStatus != null ||
                _searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedStatus = null;
                    _searchController.clear();
                  });
                  _onRefresh(context);
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _onRefresh(context);
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by ID or Reason...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              _buildFilterBar(),
              if (_selectedDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Showing requests for: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: requests.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text("No matching requests found")),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return _buildRequestCard(context, request);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(null, "All"),
          ...GatePassStatus.values.map(
            (status) => _buildFilterChip(status, status.name.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(GatePassStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedStatus = status);
            _onRefresh(context);
          }
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, GatePassRequest request) {
    // Show QR code for both Approved (to exit) and Exited (to return)
    final bool canShowQR =
        request.status == GatePassStatus.approved ||
        request.status == GatePassStatus.exited;

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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    if (request.status == GatePassStatus.exited &&
                        request.warningNotificationId != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Tracking ON",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildStatusChip(request.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpandableText(
              text: request.reason,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Register Number: ${request.registerNumber ?? 'Not provided'}",
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
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
            if (canShowQR) ...[
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
                label: Text(
                  request.status == GatePassStatus.exited
                      ? "Show QR to Return"
                      : "Show QR Code",
                ),
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
                style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13),
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
      case GatePassStatus.exited:
        color = Colors.orange;
        label = "Outside";
        break;
      case GatePassStatus.returned:
        color = Colors.blue;
        label = "Returned";
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
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
