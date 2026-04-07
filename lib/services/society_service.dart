import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/society_model.dart';

/// Service for society-related Firestore operations
class SocietyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get society by ID
  Future<SocietyModel?> getSociety(String societyId) async {
    final doc = await _firestore.collection('societies').doc(societyId).get();
    if (!doc.exists) return null;
    return SocietyModel.fromMap(doc.data()!, doc.id);
  }

  /// Stream a society document for real-time updates
  Stream<SocietyModel?> streamSociety(String societyId) {
    return _firestore
        .collection('societies')
        .doc(societyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SocietyModel.fromMap(doc.data()!, doc.id);
    });
  }
}
