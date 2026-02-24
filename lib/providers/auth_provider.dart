import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isInitialized = false;

  AuthProvider() {
    _authService.user.listen((user) async {
      _firebaseUser = user;
      if (user == null) {
        _userProfile = null;
      } else {
        await refreshProfile(user.uid);
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _firebaseUser != null;
  bool get hasProfile => _userProfile != null;

  UserRole? get userRole {
    if (_userProfile == null) return null;
    final roleStr = _userProfile!['role'] as String?;
    try {
      return UserRole.values.firstWhere((e) => e.name == roleStr);
    } catch (_) {
      return UserRole.student;
    }
  }

  String? get userName => _userProfile?['name'];

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await _authService.login(email, password);
      await refreshProfile(cred.user?.uid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await _authService.signUp(email, password);
      await refreshProfile(cred.user?.uid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile(String? uid) async {
    if (uid != null) {
      _userProfile = await _authService.getUserProfile(uid);
      await NotificationService.login(uid);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await NotificationService.logout();
    _firebaseUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> completeProfile({
    required String name,
    required UserRole role,
    required String department,
    required String registerNumber,
    required String phone,
    String? semester, // Added semester
  }) async {
    if (_firebaseUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.createUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        email: _firebaseUser!.email!,
        role: role,
        department: department,
        registerNumber: registerNumber,
        phone: phone,
        semester: semester,
      );
      await refreshProfile(_firebaseUser!.uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
