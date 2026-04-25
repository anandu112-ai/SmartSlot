import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(userCredential.user!.uid).set(user.toMap());

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint("AuthService Error: $e");
    }
    return null;
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // Password reset request
  Future<void> requestPasswordReset(String email) async {
    await _db.collection('password_requests').add({
      'email': email,
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Toggle Favorite Spot
  Future<void> toggleFavorite(String uid, String spotId) async {
    DocumentReference userRef = _db.collection('users').doc(uid);
    DocumentSnapshot doc = await userRef.get();
    List<String> favorites = List<String>.from(doc.get('favorites') ?? []);
    
    if (favorites.contains(spotId)) {
      favorites.remove(spotId);
    } else {
      favorites.add(spotId);
    }
    
    await userRef.update({'favorites': favorites});
  }

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
