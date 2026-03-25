import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';

class ApplyPassScreen extends StatefulWidget {
  const ApplyPassScreen({super.key});

  @override
  State<ApplyPassScreen> createState() => _ApplyPassScreenState();
}

class _ApplyPassScreenState extends State<ApplyPassScreen> {
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _fromTime = TimeOfDay.now();
  TimeOfDay _toTime = TimeOfDay.now();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _reasonController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
      // builder: (context, child) {
      //   return Theme(
      //     data: Theme.of(
      //       context,
      //     ).copyWith(materialTapTargetSize: MaterialTapTargetSize.padded),
      //     child: child!,
      //   );
      // },
    );

    if (picked == null) return;

    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final pickedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      picked.hour,
      picked.minute,
    );

    // 1. Enforce Future Time for Today
    if (isToday && pickedDateTime.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot select a past time for today"),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      if (isFrom) {
        _fromTime = picked;
        // 2. Ensure From Time is before To Time
        // If new From Time is after current To Time, adjust To Time to match From Time
        final toDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _toTime.hour,
          _toTime.minute,
        );

        if (toDateTime.isBefore(pickedDateTime)) {
          _toTime = picked;
        }
      } else {
        // 3. Enforce To Time is after From Time
        final fromDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _fromTime.hour,
          _fromTime.minute,
        );

        if (pickedDateTime.isBefore(fromDateTime) ||
            pickedDateTime.isAtSameMomentAs(fromDateTime)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("To Time must be after From Time"),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        _toTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gatePassProvider = context.watch<GatePassProvider>();

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text("Apply Gate Pass")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Pass Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reason for Leave",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: _listen,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? AppColors.error : AppColors.primary,
                    ),
                    tooltip: "Speak your reason",
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? "Listening..."
                      : "Enter or speak the reason...",
                  suffixIcon: _isListening
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              const Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildPickerTile(
                icon: Icons.calendar_today_rounded,
                text: DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "From Time",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildPickerTile(
                          icon: Icons.access_time_rounded,
                          text: _fromTime.format(context),
                          onTap: () => _selectTime(context, true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "To Time",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _buildPickerTile(
                          icon: Icons.access_time_rounded,
                          text: _toTime.format(context),
                          onTap: () => _selectTime(context, false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: gatePassProvider.isLoading
                    ? null
                    : () async {
                        if (_reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter a reason"),
                            ),
                          );
                          return;
                        }

                        // Final Time Validation
                        final now = DateTime.now();
                        final fromDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _fromTime.hour,
                          _fromTime.minute,
                        );
                        final toDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _toTime.hour,
                          _toTime.minute,
                        );

                        if (fromDateTime.isBefore(
                          now.subtract(const Duration(minutes: 1)),
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("From Time cannot be in the past"),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        if (!toDateTime.isAfter(fromDateTime)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("To Time must be after From Time"),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        if (auth.firebaseUser == null) return;

                        final newRequest = GatePassRequest(
                          id: "GP${DateTime.now().millisecondsSinceEpoch % 10000}",
                          studentName: auth.userName ?? "Unknown",
                          studentId: auth.firebaseUser!.uid,
                          registerNumber: auth.userProfile?['registerNumber'],
                          reason: _reasonController.text,
                          date: _selectedDate,
                          fromTime: _fromTime.format(context),
                          toTime: _toTime.format(context),
                          status: GatePassStatus.pending,
                          department: auth.userProfile?['department'],
                          semester: auth
                              .userProfile?['semester'], // Included Semester
                        );

                        await context.read<GatePassProvider>().createRequest(
                          newRequest,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Gate Pass Request Submitted"),
                            ),
                          );
                        }
                      },
                child: gatePassProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
