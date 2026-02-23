import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gatePassProvider = context.watch<GatePassProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Apply Gate Pass")),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
