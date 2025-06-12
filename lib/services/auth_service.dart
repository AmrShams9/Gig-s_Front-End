import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> roles = List<String>.from(data['roles'] ?? []);
        return roles.contains('admin');
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String governmentId,
    List<String> roles,
    String? profileImageUrl,
  ) async {
    try {
      // First create the user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Then create the user document in Firestore
      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          governmentId: governmentId,
          roles: roles,
          profileImageUrl: profileImageUrl,
          createdAt: DateTime.now(),
        );

        // Save user data to Firestore
        await _firestore.collection('users').doc(user.id).set({
          'id': user.id,
          'email': user.email,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'governmentId': user.governmentId,
          'roles': user.roles,
          'profileImageUrl': user.profileImageUrl,
          'rating': user.rating,
          'completedTasks': user.completedTasks,
          'createdAt': user.createdAt.toIso8601String(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user data: $e');
      throw Exception('Failed to update user data');
    }
  }

  // Add a role to user
  Future<void> addRole(String userId, String role) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'roles': FieldValue.arrayUnion([role])
      });
    } catch (e) {
      print('Error adding role: $e');
      throw Exception('Failed to add role');
    }
  }

  // Remove a role from user
  Future<void> removeRole(String userId, String role) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'roles': FieldValue.arrayRemove([role])
      });
    } catch (e) {
      print('Error removing role: $e');
      throw Exception('Failed to remove role');
    }
  }

  // Sign out
  Future<void> signOut() async {
    return _auth.signOut();
  }
}