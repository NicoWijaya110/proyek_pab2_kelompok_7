import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _loading = false;

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) _fetchProfile(user.uid);
      notifyListeners();
    });
  }

  Future<void> _fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      _userProfile = doc.data();
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _loading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _loading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _loading = true;
      notifyListeners();
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await cred.user?.updateDisplayName(displayName);
      // Simpan profil user ke Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'photoUrl': '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _loading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String displayName,
    required String bio,
    String? photoUrl,
  }) async {
    if (_user == null) return 'Belum login';
    try {
      await _user!.updateDisplayName(displayName);
      final data = {'displayName': displayName, 'bio': bio};
      if (photoUrl != null) {
        data['photoUrl'] = photoUrl;
        await _user!.updatePhotoURL(photoUrl);
      }
      await _db.collection('users').doc(_user!.uid).update(data);
      await _fetchProfile(_user!.uid);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refreshProfile() async {
    if (_user != null) await _fetchProfile(_user!.uid);
  }
}
