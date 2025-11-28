import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  String? _token;
  String? _email;

  String? get userId => _userId;
  String? get token => _token;
  String? get email => _email;

  void login({
    required String userId,
    required String token,
    required String email,
  }) {
    _userId = userId;
    _token = token;
    _email = email;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _token = null;
    _email = null;
    notifyListeners();
  }

  bool get isLoggedIn => _userId != null;
}
