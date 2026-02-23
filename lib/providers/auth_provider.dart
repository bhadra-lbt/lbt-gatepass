import 'package:flutter/material.dart';
import '../models/user_role.dart';

class AuthProvider extends ChangeNotifier {
  UserRole? _userRole;
  String? _userName;

  UserRole? get userRole => _userRole;
  String? get userName => _userName;

  bool get isAuthenticated => _userRole != null;

  void login(String email, String password, UserRole role) {
    // For demo purposes, we accept any login and set the role based on the selection
    _userRole = role;
    _userName = role == UserRole.student ? "John Doe" : "Prof. Smith";
    notifyListeners();
  }

  void logout() {
    _userRole = null;
    _userName = null;
    notifyListeners();
  }
}
