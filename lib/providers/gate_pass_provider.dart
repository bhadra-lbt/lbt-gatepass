import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gate_pass.dart';
import '../services/database_service.dart';

class GatePassProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<GatePassRequest> _studentRequests = [];
  List<GatePassRequest> _pendingRequests = [];
  List<GatePassRequest> _recentActivity = [];
  bool _isLoading = false;

  StreamSubscription? _studentSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _recentActivitySubscription;
  String? _lastStudentId;
  String? _lastDept;

  List<GatePassRequest> get studentRequests => _studentRequests;
  List<GatePassRequest> get pendingRequests => _pendingRequests;
  List<GatePassRequest> get recentActivity => _recentActivity;
  bool get isLoading => _isLoading;

  // Fetch requests for a specific student (real-time)
  void listenToStudentRequests(String studentId) {
    if (_lastStudentId == studentId) return; // Prevent duplicate listeners

    _studentSubscription?.cancel();
    _lastStudentId = studentId;

    _studentSubscription = _dbService.getStudentRequests(studentId).listen((
      requests,
    ) {
      // Sort locally by date descending
      requests.sort((a, b) => b.date.compareTo(a.date));
      _studentRequests = requests;
      notifyListeners();
    });
  }

  // Fetch pending requests for staff (real-time)
  void listenToPendingRequests({String? department}) {
    if (_lastDept == department) return;

    _pendingSubscription?.cancel();
    _lastDept = department;

    _pendingSubscription = _dbService
        .getPendingRequests(department: department)
        .listen((requests) {
          // Sort locally by date descending
          requests.sort((a, b) => b.date.compareTo(a.date));
          _pendingRequests = requests;
          notifyListeners();
        });
  }

  // Fetch recent gate activity (exited/returned)
  void listenToRecentActivity() {
    _recentActivitySubscription?.cancel();
    _recentActivitySubscription = _dbService.getRecentGateActivity().listen((
      requests,
    ) {
      _recentActivity = requests;
      notifyListeners();
    });
  }

  Future<void> createRequest(GatePassRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbService.createGatePassRequest(request);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(
    String id,
    GatePassStatus status, {
    String? reason,
  }) async {
    await _dbService.updateRequestStatus(id, status, rejectionReason: reason);
  }

  Future<GatePassRequest?> getRequestById(String id) async {
    return await _dbService.getRequestById(id);
  }

  Future<void> logExit(String id) async {
    await _dbService.logExit(id);
  }

  Future<void> logReturn(String id) async {
    await _dbService.logReturn(id);
  }

  @override
  void dispose() {
    _studentSubscription?.cancel();
    _pendingSubscription?.cancel();
    _recentActivitySubscription?.cancel();
    super.dispose();
  }
}
