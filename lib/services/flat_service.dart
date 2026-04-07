import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flat_model.dart';

/// Service for flat-related Firestore CRUD operations
class FlatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all flats for a society
  Stream<List<FlatModel>> streamFlats(String societyId) {
    return _firestore
        .collection('flats')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get all flats for a society (one-time fetch)
  Future<List<FlatModel>> getFlats(String societyId) async {
    final snapshot = await _firestore
        .collection('flats')
        .where('societyId', isEqualTo: societyId)
        .get();
    return snapshot.docs
        .map((doc) => FlatModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Add a new flat
  Future<void> addFlat(FlatModel flat) async {
    await _firestore.collection('flats').add(flat.toMap());
  }

  /// Update an existing flat
  Future<void> updateFlat(FlatModel flat) async {
    await _firestore.collection('flats').doc(flat.id).update(flat.toMap());
  }

  /// Delete a flat and all its associated payment records
  Future<void> deleteFlat(String flatId) async {
    // Delete all payment records for this flat
    final payments = await _firestore
        .collection('payments')
        .where('flatId', isEqualTo: flatId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in payments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('flats').doc(flatId));
    await batch.commit();
  }
}
