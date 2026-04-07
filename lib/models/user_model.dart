
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "admin" or "resident"
  final String societyId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.societyId,
  });

  /// Create UserModel from Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'resident',
      societyId: map['societyId'] ?? '',
    );
  }

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'societyId': societyId,
    };
  }

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Check if user is a resident
  bool get isResident => role == 'resident';
}
