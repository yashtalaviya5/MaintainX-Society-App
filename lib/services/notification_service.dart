import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  static final NotificationService instance = NotificationService();

  CollectionReference get _collection => _firestore.collection('notifications');

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize local notifications
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);

    // Request permission for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show a local phone notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'maintainx_channel_v2', // New channel ID to force update
      'MaintainX Alerts',
      channelDescription: 'Urgent society management notifications',
      importance: Importance.max, // Max importance for banner/sound
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Create a notification in Firestore
  Future<void> createNotification({
    required String societyId,
    String? userId,
    String? senderId,
    String? targetRole,
    required String title,
    required String body,
    required String type,
  }) async {
    await _collection.add({
      'societyId': societyId,
      'userId': userId,
      'senderId': senderId,
      'targetRole': targetRole,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Send notification to all users in a society
  Future<void> notifyAllUsers({
    required String societyId,
    required String senderId,
    String? targetRole,
    required String title,
    required String body,
    required String type,
  }) async {
    // Create a broadcast notification (userId = null means for all)
    await createNotification(
      societyId: societyId,
      senderId: senderId,
      targetRole: targetRole,
      title: title,
      body: body,
      type: type,
    );
  }

  /// Send notification to a specific user
  Future<void> notifyUser({
    required String societyId,
    required String senderId,
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await createNotification(
      societyId: societyId,
      senderId: senderId,
      userId: userId,
      title: title,
      body: body,
      type: type,
    );
  }

  /// Stream notifications for a user (broadcast + personal)
  Stream<List<NotificationModel>> streamNotifications(
      String societyId, String userId) {
    // Get broadcast + user-specific notifications
    return _collection
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .where((n) => n.userId == null || n.userId == userId)
          .toList();
      // Sort in-memory to avoid index requirement
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(50).toList(); // Keep limit 50 in-memory
    });
  }

  /// Get unread count
  Stream<int> streamUnreadCount(String societyId, String userId) {
    return streamNotifications(societyId, userId)
        .map((list) => list.where((n) => !n.isRead).length);
  }

  /// Mark notification as read
  Future<void> markRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllRead(String societyId, String userId) async {
    final snap = await _collection
        .where('societyId', isEqualTo: societyId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] == null || data['userId'] == userId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  /// Listen for new notifications and show them on phone
  void listenForNewNotifications({
    required String societyId,
    required String userId,
    required String userRole,
  }) {
    bool isFirstSnapshot = true;
    _collection
        .where('societyId', isEqualTo: societyId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (isFirstSnapshot) {
        isFirstSnapshot = false;
        return; // Skip initial unread notifications
      }

      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          final senderId = data['senderId']?.toString();
          final targetUserId = data['userId']?.toString();
          final targetRole = data['targetRole']?.toString();

          // Rule 1: Never notify the sender
          if (senderId == userId) continue;

          // Rule 2: If directed to a specific user, match them
          if (targetUserId != null) {
            if (targetUserId == userId) {
              _showIfNew(data);
            }
            continue;
          }

          // Rule 3: If directed to a specific role, match it
          if (targetRole != null) {
            if (targetRole == userRole) {
              _showIfNew(data);
            }
            continue;
          }

          // Rule 4: Otherwise, show to everyone (since targetUserId and targetRole are null)
          _showIfNew(data);
        }
      }
    });
  }

  void _showIfNew(Map<String, dynamic> data) {
    showLocalNotification(
      title: data['title'] ?? 'New Notification',
      body: data['body'] ?? '',
    );
  }
}
