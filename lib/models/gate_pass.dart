import 'package:cloud_firestore/cloud_firestore.dart';

enum GatePassStatus { pending, approved, rejected, expired, exited, returned }

class GatePassRequest {
  final String id;
  final String studentName;
  final String studentId;
  final String? registerNumber;
  final String reason;
  final DateTime date;
  final String fromTime;
  final String toTime;
  final GatePassStatus status;
  final String? rejectionReason;
  final String? department;
  final String? semester; // Added semester
  final DateTime? exitDateTime;
  final DateTime? returnDateTime;
  final String? warningNotificationId;
  final String? overdueStudentNotificationId;
  final String? overdueFacultyNotificationId;

  GatePassRequest({
    required this.id,
    required this.studentName,
    required this.studentId,
    this.registerNumber,
    required this.reason,
    required this.date,
    required this.fromTime,
    required this.toTime,
    this.status = GatePassStatus.pending,
    this.rejectionReason,
    this.department,
    this.semester,
    this.exitDateTime,
    this.returnDateTime,
    this.warningNotificationId,
    this.overdueStudentNotificationId,
    this.overdueFacultyNotificationId,
  });

  DateTime? get expiryDateTime {
    try {
      final toTimeParts = toTime.split(' ');
      final timeParts = toTimeParts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (toTimeParts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
      if (toTimeParts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool get isExpired {
    if (status == GatePassStatus.returned ||
        status == GatePassStatus.rejected) {
      return false;
    }
    final expiry = expiryDateTime;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  GatePassRequest copyWith({
    GatePassStatus? status,
    String? rejectionReason,
    DateTime? exitDateTime,
    DateTime? returnDateTime,
    String? warningNotificationId,
    String? overdueStudentNotificationId,
    String? overdueFacultyNotificationId,
  }) {
    return GatePassRequest(
      id: id,
      studentName: studentName,
      studentId: studentId,
      registerNumber: registerNumber,
      reason: reason,
      date: date,
      fromTime: fromTime,
      toTime: toTime,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      department: department,
      semester: semester,
      exitDateTime: exitDateTime ?? this.exitDateTime,
      returnDateTime: returnDateTime ?? this.returnDateTime,
      warningNotificationId:
          warningNotificationId ?? this.warningNotificationId,
      overdueStudentNotificationId:
          overdueStudentNotificationId ?? this.overdueStudentNotificationId,
      overdueFacultyNotificationId:
          overdueFacultyNotificationId ?? this.overdueFacultyNotificationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentId': studentId,
      'registerNumber': registerNumber,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'fromTime': fromTime,
      'toTime': toTime,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'department': department,
      'semester': semester,
      'exitDateTime': exitDateTime != null
          ? Timestamp.fromDate(exitDateTime!)
          : null,
      'returnDateTime': returnDateTime != null
          ? Timestamp.fromDate(returnDateTime!)
          : null,
      'expiryDateTime': expiryDateTime != null
          ? Timestamp.fromDate(expiryDateTime!)
          : null,
      'warningNotificationId': warningNotificationId,
      'overdueStudentNotificationId': overdueStudentNotificationId,
      'overdueFacultyNotificationId': overdueFacultyNotificationId,
    };
  }

  factory GatePassRequest.fromMap(Map<String, dynamic> map) {
    return GatePassRequest(
      id: map['id'] ?? '',
      studentName: map['studentName'] ?? '',
      studentId: map['studentId'] ?? '',
      registerNumber: map['registerNumber'],
      reason: map['reason'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      fromTime: map['fromTime'] ?? '',
      toTime: map['toTime'] ?? '',
      status: GatePassStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GatePassStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      department: map['department'],
      semester: map['semester'],
      exitDateTime: map['exitDateTime'] != null
          ? (map['exitDateTime'] as Timestamp).toDate()
          : null,
      returnDateTime: map['returnDateTime'] != null
          ? (map['returnDateTime'] as Timestamp).toDate()
          : null,
      warningNotificationId: map['warningNotificationId'],
      overdueStudentNotificationId: map['overdueStudentNotificationId'],
      overdueFacultyNotificationId: map['overdueFacultyNotificationId'],
    );
  }
}
