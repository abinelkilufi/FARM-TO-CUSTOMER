import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = false;
  User? _user;
  UserModel? _userModel;
  String? _role;
  String? _errorMessage;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  User? get user => _user;
  UserModel? get userModel => _userModel;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user == null) {
      _role = null;
      _userModel = null;
      _notify();
      return;
    }

    if (_isLoading) {
      _notify();
      return;
    }

    try {
      final document = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      final data = document.data();
      if (data != null) {
        _userModel = UserModel.fromMap(data, docId: document.id);
        _role = _normalizeRole(data['role'] as String?);
      }
    } catch (_) {
      // Keep the current profile. AuthWrapper surfaces profile loading errors.
    }

    _notify();
  }

  Future<bool> signUp(
    String name,
    String email,
    String password,
    String role,
    String phone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _errorMessage = 'Unable to create your account. Please try again.';
        return false;
      }

      final normalizedRole = _normalizeRole(role) ?? 'consumer';
      final createdAt = DateTime.now();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set({
            'uid': firebaseUser.uid,
            'name': name.trim(),
            'email': email.trim(),
            'role': normalizedRole,
            'phone': phone.trim(),
            'location': '',
            'profileImageUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
          });

      try {
        await firebaseUser.updateDisplayName(name.trim());
      } catch (_) {
        // Non-critical. The display name is also stored in Firestore.
      }

      _user = firebaseUser;
      _role = normalizedRole;
      _userModel = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: userRoleFromString(normalizedRole),
        location: '',
        profileImageUrl: null,
        createdAt: createdAt,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapAuthError(error);
      return false;
    } on FirebaseException catch (error) {
      await _rollbackAuthUser();
      _user = null;
      _role = null;
      _userModel = null;
      _errorMessage =
          error.message ?? 'We could not save your account. Please try again.';
      return false;
    } catch (_) {
      await _rollbackAuthUser();
      _user = null;
      _role = null;
      _userModel = null;
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _role = null;
    _userModel = null;
    _notify();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _errorMessage = 'Unable to sign in. Please try again.';
        return false;
      }

      final document = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!document.exists) {
        await _auth.signOut();
        _user = null;
        _role = null;
        _userModel = null;
        _errorMessage =
            'No profile was found for this account. Please contact support.';
        return false;
      }

      final data = document.data() ?? <String, dynamic>{};

      _user = firebaseUser;
      _role = _normalizeRole(data['role'] as String?);
      _userModel = UserModel.fromMap(data, docId: document.id);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapAuthError(error);
      return false;
    } on FirebaseException catch (error) {
      await _auth.signOut();
      _user = null;
      _role = null;
      _userModel = null;
      _errorMessage =
          error.message ?? 'Unable to load your profile. Please try again.';
      return false;
    } catch (_) {
      await _auth.signOut();
      _user = null;
      _role = null;
      _userModel = null;
      _errorMessage = 'Unable to sign in right now. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> refreshUserModel() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _userModel = null;
      _role = null;
      _notify();
      return;
    }

    try {
      final document = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();

      if (document.exists) {
        final data = document.data() ?? <String, dynamic>{};
        _userModel = UserModel.fromMap(data, docId: document.id);
        _role = _normalizeRole(data['role'] as String?);
      }
    } catch (_) {
      // Ignore refresh failures; the existing profile remains displayed.
    }

    _notify();
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapAuthError(error);
    } catch (_) {
      _errorMessage = 'Unable to sign out. Please try again.';
    } finally {
      _user = null;
      _userModel = null;
      _role = null;
      _isLoading = false;
      _notify();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _notify();
  }

  String? _normalizeRole(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    switch (value.trim().toLowerCase()) {
      case 'farmer':
        return 'farmer';
      case 'trader':
      case 'traders':
        return 'trader';
      case 'consumer':
        return 'consumer';
      default:
        return value.trim().toLowerCase();
    }
  }

  Future<void> _rollbackAuthUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await currentUser.delete();
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {
        // Nothing else can be done here.
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account was found for that email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
