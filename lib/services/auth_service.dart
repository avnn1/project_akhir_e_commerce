import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  String? _userRole;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _fetchUserRole(user.uid);
      } else {
        _userRole = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'buyer';
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> register(String name, String email, String password, String role) async {
    try {
      _isLoading = true;
      notifyListeners();
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
