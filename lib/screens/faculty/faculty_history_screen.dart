import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/expandable_text.dart';

class FacultyHistoryScreen extends StatefulWidget {
  final String department;
  const FacultyHistoryScreen({super.key, required this.department});

  @override
  State<FacultyHistoryScreen> createState() => _FacultyHistoryScreenState();
}

class _FacultyHistoryScreenState extends State<FacultyHistoryScreen> {
  DateTime? _selectedDate;
  GatePassStatus? _selectedStatus;
  String? _selectedSemester;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<GatePassProvider>().listenToFilteredActivity(
      department: widget.department,
      status: _selectedStatus,
      date: _selectedDate,
      semester: _selectedSemester,
      searchQuery: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GatePassProvider>();
    final history = provider.filteredActivity;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("${widget.department} History"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedStatus = null;
                _selectedSemester = null;
                _searchController.clear();
              });
              _fetchData();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchData();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: history.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text("No records found.")),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _buildHistoryCard(history[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // 1. Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search student name or GP ID...",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _fetchData();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            onChanged: (val) => _fetchData(),
          ),
          const SizedBox(height: 12),
          // 2. Dropdown Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdownFilter<GatePassStatus?>(
                  label: "Status",
                  value: _selectedStatus,
                  items: [null, ...GatePassStatus.values],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _fetchData();
                  },
                  itemLabel: (val) =>
                      val == null ? "ALL STATUS" : val.name.toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildDropdownFilter<String?>(
                  label: "Sem",
                  value: _selectedSemester,
                  items: [null, "1", "2", "3", "4", "5", "6", "7", "8"],
                  onChanged: (val) {
                    setState(() => _selectedSemester = val);
                    _fetchData();
                  },
                  itemLabel: (val) => val == null ? "SET" : "S$val",
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    _fetchData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedDate != null
                        ? AppColors.primary.withOpacity(0.05)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: _selectedDate != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          items: items.map((i) {
            return DropdownMenuItem<T>(value: i, child: Text(itemLabel(i)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(GatePassRequest request) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "S${request.semester} • ${request.registerNumber}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('dd MMM').format(request.date)} • ${request.fromTime} - ${request.toTime}",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpandableText(
              text: request.reason,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
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
      case GatePassStatus.exited:
        color = Colors.orange;
        label = "Outside";
        break;
      case GatePassStatus.returned:
        color = Colors.blue;
        label = "Returned";
        break;
      case GatePassStatus.expired:
        color = Colors.grey;
        label = "Expired";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
