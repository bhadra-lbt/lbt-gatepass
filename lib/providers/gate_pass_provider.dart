import 'package:flutter/material.dart';
import '../models/gate_pass.dart';

class GatePassProvider extends ChangeNotifier {
  final List<GatePassRequest> _requests = [
    GatePassRequest(
      id: "GP123",
      studentName: "John Doe",
      studentId: "ST001",
      reason: "Medical Emergency",
      date: DateTime.now(),
      fromTime: "10:30 AM",
      toTime: "02:00 PM",
      status: GatePassStatus.approved,
    ),
    GatePassRequest(
      id: "GP124",
      studentName: "Jane Smith",
      studentId: "ST002",
      reason: "Hostel Visit",
      date: DateTime.now(),
      fromTime: "01:00 PM",
      toTime: "04:00 PM",
      status: GatePassStatus.pending,
    ),
  ];

  List<GatePassRequest> get requests => _requests;

  List<GatePassRequest> get pendingRequests =>
      _requests.where((r) => r.status == GatePassStatus.pending).toList();

  void addRequest(GatePassRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }

  void updateRequestStatus(String id, GatePassStatus status) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      notifyListeners();
    }
  }
}
