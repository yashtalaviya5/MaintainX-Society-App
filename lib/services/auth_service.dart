import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles all authentication operations using Firebase Auth + Firestore
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Check if email is verified
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email first. Check your inbox.');
      }

      // Fetch user document from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found. Please contact admin.');
      }

      return UserModel.fromMap(userDoc.data()!, userDoc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Admin signup - creates account, society, and user document
  Future<UserModel> adminSignup({
    required String name,
    required String email,
    required String password,
    required String societyName,
    required String city,
    required String address,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final userId = credential.user!.uid;

      // 2. Generate society document (auto-ID)
      final societyRef = _firestore.collection('societies').doc();
      final societyId = societyRef.id;

      // 3. Create society document
      await societyRef.set({
        'societyName': societyName,
        'city': city,
        'address': address,
        'adminUserId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create user document
      final userData = {
        'name': name,
        'email': email.trim(),
        'role': 'admin',
        'societyId': societyId,
      };
      await _firestore.collection('users').doc(userId).set(userData);

      return UserModel(
        id: userId,
        name: name,
        email: email.trim(),
        role: 'admin',
        societyId: societyId,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Resident signup - creates account, then validates society ID
  Future<UserModel> residentSignup({
    required String name,
    required String email,
    required String password,
    required String societyId,
  }) async {
    try {
      // 1. Create Firebase Auth account FIRST (so we're authenticated for Firestore)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final userId = credential.user!.uid;

      // 2. Now validate society exists (user is authenticated, Firestore allows read)
      final societyDoc = await _firestore
          .collection('societies')
          .doc(societyId.trim())
          .get();

      if (!societyDoc.exists) {
        // Society not found — rollback: delete the auth account
        await credential.user!.delete();
        throw Exception('Society not found. Please check the Society ID.');
      }

      // 3. Create user document
      final userData = {
        'name': name,
        'email': email.trim(),
        'role': 'resident',
        'societyId': societyId.trim(),
      };
      await _firestore.collection('users').doc(userId).set(userData);

      return UserModel(
        id: userId,
        name: name,
        email: email.trim(),
        role: 'resident',
        societyId: societyId.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Fetch current user's profile from Firestore
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Update user profile name in Firestore
  Future<void> updateProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
    });
  }

  /// Change password (requires current password for re-authentication)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Convert Firebase Auth errors to user-friendly messages
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
        return Exception('Invalid password. Please try again.');
      case 'invalid-credential':
        return Exception('Invalid password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password is too weak. Use at least 6 characters.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}
