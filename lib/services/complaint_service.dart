import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import 'notification_service.dart';

/// Service for complaint-related Firestore CRUD operations
class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all complaints for a society (for admin)
  Stream<List<ComplaintModel>> streamComplaints(String societyId) {
    return _firestore
        .collection('complaints')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  /// Stream complaints for a specific user (for resident)
  Stream<List<ComplaintModel>> streamUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  /// Add a new complaint
  Future<void> addComplaint(ComplaintModel complaint) async {
    await _firestore.collection('complaints').add(complaint.toMap());

    // Notify admins (broadcast to society, targetRole: 'admin')
    await NotificationService.instance.createNotification(
      societyId: complaint.societyId,
      senderId: complaint.userId,
      targetRole: 'admin',
      title: 'New Complaint Filed',
      body: 'Flat ${complaint.flatId}: ${complaint.title}',
      type: 'complaint',
    );
  }

  /// Update complaint status (admin only)
  Future<void> updateStatus(String complaintId, String newStatus) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': newStatus,
    });
  }

  /// Get count of open complaints for a society
  Future<int> getOpenComplaintsCount(String societyId) async {
    final snapshot = await _firestore
        .collection('complaints')
        .where('societyId', isEqualTo: societyId)
        .where('status', isEqualTo: 'open')
        .get();
    return snapshot.docs.length;
  }

  /// Get all complaints for a society (one-time fetch)
  Future<List<ComplaintModel>> getComplaints(String societyId) async {
    final snapshot = await _firestore
        .collection('complaints')
        .where('societyId', isEqualTo: societyId)
        .get();
    return snapshot.docs
        .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
