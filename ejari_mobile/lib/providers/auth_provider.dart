import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? newUser) {
      _user = newUser;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.createUserWithEmailAndPassword(
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
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
