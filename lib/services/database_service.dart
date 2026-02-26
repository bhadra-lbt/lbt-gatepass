import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gate_pass.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _gatePasses => _firestore.collection('gate_passes');

  // Create a new gate pass request
  Future<void> createGatePassRequest(GatePassRequest request) async {
    await _gatePasses.doc(request.id).set(request.toMap());
  }

  // Get all requests for a specific student
  Stream<List<GatePassRequest>> getStudentRequests(String studentId) {
    return _gatePasses.where('studentId', isEqualTo: studentId).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return GatePassRequest.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
      },
    );
  }

  // Get all pending requests for staff/HOD
  Stream<List<GatePassRequest>> getPendingRequests({String? department}) {
    Query query = _gatePasses.where(
      'status',
      isEqualTo: GatePassStatus.pending.name,
    );

    if (department != null && department != "All") {
      if (department == "CSE") {
        query = query.where('department', whereIn: ['CSE 1', 'CSE 2']);
      } else {
        query = query.where('department', isEqualTo: department);
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GatePassRequest.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update request status (Approve/Reject)
  Future<void> updateRequestStatus(
    String id,
    GatePassStatus status, {
    String? rejectionReason,
  }) async {
    await _gatePasses.doc(id).update({
      'status': status.name,
      'rejectionReason': ?rejectionReason,
    });
  }

  // Record student exit
  Future<void> logExit(String id) async {
    await _gatePasses.doc(id).update({
      'status': GatePassStatus.exited.name,
      'exitDateTime': FieldValue.serverTimestamp(),
    });
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
    if (doc.exists) {
      return GatePassRequest.fromMap(doc.data() as Map<String, dynamic>);
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
            return GatePassRequest.fromMap(doc.data() as Map<String, dynamic>);
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
    // Determine parent department (e.g., "CSE 1" -> "CSE")
    String parentDept = studentDept.split(' ')[0];

    // Fetch all staff and HODs (Small collection, efficient to filter)
    final snapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['staff', 'hod'])
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final role = data['role'];
          final userDept = data['department'];

          // Condition 1: Staff member in the student's specific section
          if (role == 'staff' && userDept == studentDept) return true;

          // Condition 2: HOD of the parent department
          if (role == 'hod' && userDept == parentDept) return true;

          return false;
        })
        .map((doc) => doc.id)
        .toList();
  }
}
