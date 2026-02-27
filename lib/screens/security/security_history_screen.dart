import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/gate_pass_provider.dart';

class SecurityHistoryScreen extends StatefulWidget {
  const SecurityHistoryScreen({super.key});

  @override
  State<SecurityHistoryScreen> createState() => _SecurityHistoryScreenState();
}

class _SecurityHistoryScreenState extends State<SecurityHistoryScreen> {
  DateTime? _selectedDate;
  String? _selectedDept = "All";
  GatePassStatus? _selectedStatus;
  String? _selectedSemester;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<GatePassProvider>().listenToFilteredActivity(
      department: _selectedDept,
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
        title: const Text("Gate Pass Archive"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
                _selectedDept = "All";
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
                        Center(
                          child: Text("No records found for these filters."),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              hintText: "Search name, ID...",
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            onChanged: (val) => _fetchData(),
          ),
          const SizedBox(height: 12),
          // 2. Multi-column filters
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter<String?>(
                  label: "Dept",
                  value: _selectedDept,
                  items: ["All", "CSE", "ECE", "ME", "CE", "EEE"],
                  onChanged: (val) {
                    setState(() => _selectedDept = val ?? "All");
                    _fetchData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter<String?>(
                  label: "Sem",
                  value: _selectedSemester,
                  items: [null, "1", "2", "3", "4", "5", "6", "7", "8"],
                  onChanged: (val) {
                    setState(() => _selectedSemester = val);
                    _fetchData();
                  },
                  itemLabel: (val) => val == null ? "ALL" : "S$val",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdownFilter<GatePassStatus?>(
                  label: "Status",
                  value: _selectedStatus,
                  items: [null, ...GatePassStatus.values],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _fetchData();
                  },
                  itemLabel: (val) => val?.name.toUpperCase() ?? "ALL",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2026),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _fetchData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                color: _selectedDate != null
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: _selectedDate != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? "Filter by Date"
                        : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedDate == null
                          ? Colors.grey
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = null);
                        _fetchData();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
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
    String Function(T)? itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items.map((i) {
                return DropdownMenuItem<T>(
                  value: i,
                  child: Text(
                    itemLabel?.call(i) ?? i.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(GatePassRequest request) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          request.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "S${request.semester ?? '?'} ${request.department ?? 'N/A'}\n${DateFormat('dd MMM').format(request.date)} • ${request.reason}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              request.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(request.status),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.toTime,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
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
      case GatePassStatus.expired:
        return Colors.grey;
      case GatePassStatus.pending:
        return AppColors.warning;
    }
  }
}
