import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gate_pass.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _gatePasses => _firestore.collection('gate_passes');

  // Create a new gate pass request
  Future<void> createGatePassRequest(GatePassRequest request) async {
    await _gatePasses.doc(request.id).set(request.toMap());
  }

  // Get all requests for a specific student (with optional date and status filters)
  Stream<List<GatePassRequest>> getStudentRequests(
    String studentId, {
    DateTime? date,
    GatePassStatus? status,
  }) {
    var query = _gatePasses.where('studentId', isEqualTo: studentId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GatePassRequest.fromMap(doc.data());
      }).toList();
    });
  }

  // Get overdue requests (Exited but past expiry time)
  Stream<List<GatePassRequest>> getOverdueRequests({String? department, bool isHod = false}) {
    Query<Map<String, dynamic>> query = _gatePasses.where(
      'status',
      isEqualTo: GatePassStatus.exited.name,
    );

    query = _applyDepartmentFilter(query, department, isHod: isHod);

    return query.snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) {
            return GatePassRequest.fromMap(doc.data());
          })
          .where((req) {
            final expiry = req.expiryDateTime;
            return expiry != null && now.isAfter(expiry);
          })
          .toList();
    });
  }

  // Helper to handle hierarchical department filtering (e.g. CSE includes CSE 1, CSE 2)
  Query<Map<String, dynamic>> _applyDepartmentFilter(Query<Map<String, dynamic>> query, String? department, {bool isHod = false}) {
    if (department == null || department == "All") return query;
    
    if (isHod) {
      return query
          .where('department', isGreaterThanOrEqualTo: department)
          .where('department', isLessThanOrEqualTo: '$department\uf8ff');
    } else {
      return query.where('department', isEqualTo: department);
    }
  }

  // Comprehensive query for all gate passes (for Security/Admins/Faculty History)
  Stream<List<GatePassRequest>> getFilteredGatePasses({
    String? department,
    bool isHod = false,
    GatePassStatus? status,
    DateTime? date,
    String? semester,
  }) {
    Query<Map<String, dynamic>> query = _gatePasses;

    query = _applyDepartmentFilter(query, department, isHod: isHod);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (semester != null && semester != "All") {
      query = query.where('semester', isEqualTo: semester);
    }

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        return GatePassRequest.fromMap(doc.data());
      }).toList();

      // Sort by date descending
      docs.sort((a, b) => b.date.compareTo(a.date));
      return docs;
    });
  }

  // Fetch unique students under a department
  Stream<List<Map<String, dynamic>>> getStudentsByDepartment({
    String? department,
    bool isHod = false,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'student');

    query = _applyDepartmentFilter(query, department, isHod: isHod);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get all pending requests for staff/HOD
  Stream<List<GatePassRequest>> getPendingRequests({String? department, bool isHod = false}) {
    Query<Map<String, dynamic>> query = _gatePasses.where(
      'status',
      isEqualTo: GatePassStatus.pending.name,
    );

    query = _applyDepartmentFilter(query, department, isHod: isHod);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GatePassRequest.fromMap(doc.data());
      }).toList();
    });
  }

  // Update request status (Approve/Reject)
  Future<void> updateRequestStatus(
    String id,
    GatePassStatus status, {
    String? rejectionReason,
    String? approvedByName,
    String? approvedByPhone,
    String? approvedByRole,
  }) async {
    final Map<String, dynamic> data = {
      'status': status.name,
    };
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    if (approvedByName != null) data['approvedByName'] = approvedByName;
    if (approvedByPhone != null) data['approvedByPhone'] = approvedByPhone;
    if (approvedByRole != null) data['approvedByRole'] = approvedByRole;

    await _gatePasses.doc(id).update(data);
  }

  // Record student exit with notification tracking
  Future<void> logExit(
    String id, {
    String? warningId,
    String? overdueStudentId,
    String? overdueFacultyId,
  }) async {
    final Map<String, dynamic> data = {
      'status': GatePassStatus.exited.name,
      'exitDateTime': FieldValue.serverTimestamp(),
    };

    if (warningId != null) data['warningNotificationId'] = warningId;
    if (overdueStudentId != null) {
      data['overdueStudentNotificationId'] = overdueStudentId;
    }
    if (overdueFacultyId != null) {
      data['overdueFacultyNotificationId'] = overdueFacultyId;
    }

    await _gatePasses.doc(id).update(data);
  }

  // Record student return
  Future<void> logReturn(String id) async {
    await _gatePasses.doc(id).update({
      'status': GatePassStatus.returned.name,
      'returnDateTime': FieldValue.serverTimestamp(),
    });
  }

  // Get a single request by ID
  Future<GatePassRequest?> getRequestById(String id) async {
    final doc = await _gatePasses.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return GatePassRequest.fromMap(doc.data()!);
    }
    return null;
  }

  // Get recent activity for security (exited or returned)
  Stream<List<GatePassRequest>> getRecentGateActivity() {
    return _gatePasses
        .where(
          'status',
          whereIn: [GatePassStatus.exited.name, GatePassStatus.returned.name],
        )
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            return GatePassRequest.fromMap(doc.data());
          }).toList();

          // Sort by latest activity (either exit or return time)
          docs.sort((a, b) {
            final aTime =
                a.returnDateTime ??
                a.exitDateTime ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.returnDateTime ??
                b.exitDateTime ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          return docs;
        });
  }

  // Get UIDs for hierarchical notifications (Section Staff + Parent HOD)
  Future<List<String>> getDepartmentFacultyIds(String studentDept) async {
    String parentDept = studentDept.split(' ')[0];

    final snapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['staff', 'hod'])
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final role = data['role'];
          final userDept = data['department'];
          if (role == 'staff' && userDept == studentDept) return true;
          if (role == 'hod' && userDept == parentDept) return true;
          return false;
        })
        .map((doc) => doc.id)
        .toList();
  }

  // Get all staff members for a specific department
  Future<List<Map<String, dynamic>>> getDepartmentStaffMembers(
    String studentDept,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .where('department', isEqualTo: studentDept)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
