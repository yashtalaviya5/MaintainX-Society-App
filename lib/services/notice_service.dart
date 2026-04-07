import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import 'notification_service.dart';

/// Service for notice-related Firestore CRUD operations
class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all notices for a society
  Stream<List<NoticeModel>> streamNotices(String societyId) {
    return _firestore
        .collection('notices')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  /// Add a new notice
  Future<void> addNotice(NoticeModel notice, String senderId) async {
    await _firestore.collection('notices').add(notice.toMap());

    // Notify all residents
    await NotificationService.instance.notifyAllUsers(
      societyId: notice.societyId,
      senderId: senderId,
      targetRole: 'resident',
      title: 'New Notice: ${notice.title}',
      body: notice.description,
      type: 'notice',
    );
  }

  /// Update an existing notice
  Future<void> updateNotice(String noticeId, String title, String description) async {
    await _firestore.collection('notices').doc(noticeId).update({
      'title': title,
      'description': description,
    });
  }

  /// Delete a notice
  Future<void> deleteNotice(String noticeId) async {
    await _firestore.collection('notices').doc(noticeId).delete();
  }
}
