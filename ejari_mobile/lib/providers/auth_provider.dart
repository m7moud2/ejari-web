import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Demo / offline builds must never touch Firebase — accessing
    // FirebaseAuth.instance without initializeApp crashes Android release.
    if (AppConfig.demoMode) return;
    try {
      if (Firebase.apps.isEmpty) return;
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((User? newUser) {
        _user = newUser;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthProvider Firebase skipped: $e');
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      _setLoading(true);
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      _setLoading(true);
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
