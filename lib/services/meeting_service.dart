import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import 'notification_service.dart';

class MeetingService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('meetings');

  /// Schedule a new meeting
  Future<void> scheduleMeeting(MeetingModel meeting, String senderId) async {
    await _collection.add(meeting.toMap());

    // Notify all residents
    await NotificationService.instance.notifyAllUsers(
      societyId: meeting.societyId,
      senderId: senderId,
      targetRole: 'resident',
      title: 'New Meeting Scheduled',
      body: '${meeting.title} on ${meeting.date.day}/${meeting.date.month} at ${meeting.time}',
      type: 'meeting',
    );
  }

  /// Stream all meetings for a society (newest first)
  Stream<List<MeetingModel>> streamMeetings(String societyId) {
    return _collection
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => MeetingModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Delete a meeting
  Future<void> deleteMeeting(String meetingId) async {
    await _collection.doc(meetingId).delete();
  }
}
