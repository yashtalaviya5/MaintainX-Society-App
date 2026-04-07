import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/party_request_model.dart';
import 'notification_service.dart';

class PartyService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('party_requests');

  /// Submit a party request
  Future<void> submitRequest(PartyRequestModel request) async {
    await _collection.add(request.toMap());

    // Notify admins (targetRole: 'admin')
    await NotificationService.instance.createNotification(
      societyId: request.societyId,
      senderId: request.userId,
      targetRole: 'admin',
      title: 'New Party Request',
      body: 'Flat ${request.flatNumber}: ${request.title}',
      type: 'party',
    );
  }

  /// Approve a party request
  Future<void> approveRequest(PartyRequestModel request, String adminId) async {
    await _collection.doc(request.id).update({'status': 'approved'});

    // Notify the user who requested it
    await NotificationService.instance.notifyUser(
      societyId: request.societyId,
      senderId: adminId,
      userId: request.userId,
      title: 'Party Request Approved! ✅',
      body: 'Your request for "${request.title}" was approved.',
      type: 'party',
    );
  }

  /// Reject a party request
  Future<void> rejectRequest(PartyRequestModel request, String adminId) async {
    await _collection.doc(request.id).update({'status': 'rejected'});

    // Notify the user who requested it
    await NotificationService.instance.notifyUser(
      societyId: request.societyId,
      senderId: adminId,
      userId: request.userId,
      title: 'Party Request Rejected ❌',
      body: 'Your request for "${request.title}" was rejected.',
      type: 'party',
    );
  }

  /// Stream all requests for a society (newest first)
  Stream<List<PartyRequestModel>> streamRequests(String societyId) {
    return _collection
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => PartyRequestModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream requests for a specific user
  Stream<List<PartyRequestModel>> streamUserRequests(
      String societyId, String userId) {
    return _collection
        .where('societyId', isEqualTo: societyId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => PartyRequestModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
