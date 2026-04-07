import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'notification_service.dart';

class EventService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('events');

  /// Create a new event
  Future<void> createEvent(EventModel event, String senderId) async {
    await _collection.add(event.toMap());

    // Notify all residents
    await NotificationService.instance.notifyAllUsers(
      societyId: event.societyId,
      senderId: senderId,
      targetRole: 'resident',
      title: 'New Event: ${event.title}',
      body: 'Date: ${event.date.day}/${event.date.month} at ${event.time}',
      type: 'event',
    );
  }

  /// Stream all events for a society (newest first)
  Stream<List<EventModel>> streamEvents(String societyId) {
    return _collection
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _collection.doc(eventId).delete();
  }
}
