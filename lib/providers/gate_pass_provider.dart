import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gate_pass.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class GatePassProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<GatePassRequest> _studentRequests = [];
  List<GatePassRequest> _pendingRequests = [];
  List<GatePassRequest> _recentActivity = [];
  List<GatePassRequest> _overdueRequests = [];
  List<GatePassRequest> _activeOutsideRequests = [];
  List<GatePassRequest> _filteredActivity = [];
  bool _isLoading = false;

  StreamSubscription? _studentSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _recentActivitySubscription;
  StreamSubscription? _overdueSubscription;
  StreamSubscription? _activeOutsideSubscription;
  StreamSubscription? _filteredSubscription;
  String? _lastStudentId;
  String? _lastDept;

  List<GatePassRequest> get studentRequests => _studentRequests;
  List<GatePassRequest> get pendingRequests => _pendingRequests;
  List<GatePassRequest> get recentActivity => _recentActivity;
  List<GatePassRequest> get overdueRequests => _overdueRequests;
  List<GatePassRequest> get activeOutsideRequests => _activeOutsideRequests;
  List<GatePassRequest> get filteredActivity => _filteredActivity;
  bool get isLoading => _isLoading;

  // Fetch requests for a specific student (real-time)
  void listenToStudentRequests(
    String studentId, {
    DateTime? date,
    GatePassStatus? status,
  }) {
    if (_lastStudentId == studentId && date == null && status == null) return;

    _studentSubscription?.cancel();
    _lastStudentId = studentId;

    _studentSubscription = _dbService
        .getStudentRequests(studentId, date: date, status: status)
        .listen((requests) {
          // Sort locally by date descending
          requests.sort((a, b) => b.date.compareTo(a.date));
          _studentRequests = requests;
          notifyListeners();
        });
  }

  void listenToOverdueRequests({String? department}) {
    _overdueSubscription?.cancel();
    _overdueSubscription = _dbService
        .getOverdueRequests(department: department)
        .listen((requests) {
          _overdueRequests = requests;
          notifyListeners();
        });
  }

  // NEW: Fetch all students currently outside for HOD/Staff stats
  void listenToActiveOutsideRequests({String? department}) {
    _activeOutsideSubscription?.cancel();
    _activeOutsideSubscription = _dbService
        .getFilteredGatePasses(
          department: department,
          status: GatePassStatus.exited,
        )
        .listen((requests) {
          _activeOutsideRequests = requests;
          notifyListeners();
        });
  }

  // NEW: Comprehensive filtered activity for Security / Faculty History
  void listenToFilteredActivity({
    String? department,
    GatePassStatus? status,
    DateTime? date,
    String? semester,
    String? searchQuery,
  }) {
    _filteredSubscription?.cancel();
    _filteredSubscription = _dbService
        .getFilteredGatePasses(
          department: department,
          status: status,
          date: date,
          semester: semester,
        )
        .listen((requests) {
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            _filteredActivity = requests.where((req) {
              return req.studentName.toLowerCase().contains(query) ||
                  req.id.toLowerCase().contains(query);
            }).toList();
          } else {
            _filteredActivity = requests;
          }
          notifyListeners();
        });
  }

  // Fetch pending requests for staff (real-time)

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

      // Trigger Notification to HOD/Staff via OneSignal
      if (request.department != null) {
        final facultyIds = await _dbService.getDepartmentFacultyIds(
          request.department!,
        );
        await NotificationService.sendNotification(
          playerIds: facultyIds,
          title: "New Gate Pass Request",
          body: "${request.studentName} has submitted a new request.",
        );
      }
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

    // Trigger Notification to Student via OneSignal
    final request = await _dbService.getRequestById(id);
    if (request != null) {
      await NotificationService.sendNotification(
        playerIds: [request.studentId],
        title: "Gate Pass ${status.name.toUpperCase()}",
        body: "Your request for ${request.reason} has been ${status.name}.",
      );
    }
  }

  Future<GatePassRequest?> getRequestById(String id) async {
    return await _dbService.getRequestById(id);
  }

  Future<void> logExit(String id) async {
    // 1. Fetch request details to calculate expiration
    final request = await _dbService.getRequestById(id);
    if (request == null) return;

    String? warningId;
    String? overdueStudentId;
    String? overdueFacultyId;

    final expiry = request.expiryDateTime;
    if (expiry != null) {
      final now = DateTime.now();

      // Feature 1: Expiry Warning (5 minutes before)
      final warningTime = expiry.subtract(const Duration(minutes: 5));
      if (warningTime.isAfter(now)) {
        warningId = await NotificationService.sendNotification(
          playerIds: [request.studentId],
          title: "Gate Pass Expiry Warning",
          body:
              "Your gate pass will expire in 5 minutes at ${request.toTime}. Please return to campus.",
          sendAfter: warningTime,
        );
      }

      // Feature 2: Overdue Notification (exactly at expiry)
      if (expiry.isAfter(now)) {
        // To Student
        overdueStudentId = await NotificationService.sendNotification(
          playerIds: [request.studentId],
          title: "Gate Pass Expired",
          body: "Your gate pass has expired. You are marked as overdue.",
          sendAfter: expiry,
        );

        // To Faculty (Staff Advisor + HOD)
        if (request.department != null) {
          final facultyIds = await _dbService.getDepartmentFacultyIds(
            request.department!,
          );
          overdueFacultyId = await NotificationService.sendNotification(
            playerIds: facultyIds,
            title: "Student Overdue Alert",
            body:
                "${request.studentName} has not returned to college after exit. Pass ID: ${request.id}",
            sendAfter: expiry,
          );
        }
      }
    }

    // 2. Perform log with stored notification IDs for tracking
    await _dbService.logExit(
      id,
      warningId: warningId,
      overdueStudentId: overdueStudentId,
      overdueFacultyId: overdueFacultyId,
    );
  }

  Future<void> logReturn(String id) async {
    // 1. Fetch request to check for pending scheduled notifications
    final request = await _dbService.getRequestById(id);
    if (request != null) {
      // Cancel scheduled notifications if they haven't fired yet
      if (request.warningNotificationId != null) {
        await NotificationService.cancelNotification(
          request.warningNotificationId!,
        );
      }
      if (request.overdueStudentNotificationId != null) {
        await NotificationService.cancelNotification(
          request.overdueStudentNotificationId!,
        );
      }
      if (request.overdueFacultyNotificationId != null) {
        await NotificationService.cancelNotification(
          request.overdueFacultyNotificationId!,
        );
      }
    }

    // 2. Perform log return
    await _dbService.logReturn(id);
  }

  @override
  void dispose() {
    _studentSubscription?.cancel();
    _pendingSubscription?.cancel();
    _recentActivitySubscription?.cancel();
    _overdueSubscription?.cancel();
    _activeOutsideSubscription?.cancel();
    _filteredSubscription?.cancel();
    super.dispose();
  }
}
