enum GatePassStatus { pending, approved, rejected, expired }

class GatePassRequest {
  final String id;
  final String studentName;
  final String studentId;
  final String reason;
  final DateTime date;
  final String fromTime;
  final String toTime;
  final GatePassStatus status;
  final String? rejectionReason;

  GatePassRequest({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.reason,
    required this.date,
    required this.fromTime,
    required this.toTime,
    this.status = GatePassStatus.pending,
    this.rejectionReason,
  });

  GatePassRequest copyWith({GatePassStatus? status, String? rejectionReason}) {
    return GatePassRequest(
      id: id,
      studentName: studentName,
      studentId: studentId,
      reason: reason,
      date: date,
      fromTime: fromTime,
      toTime: toTime,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
