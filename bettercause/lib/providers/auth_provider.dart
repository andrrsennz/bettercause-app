import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ 1. Add this import

class AuthProvider extends ChangeNotifier {
  // ✅ 2. Create the storage instance
  final _storage = const FlutterSecureStorage();

  String? _userId;
  String? _token;
  String? _email;

  String? get userId => _userId;
  String? get token => _token;
  String? get email => _email;

  // ✅ 3. Make this function 'async' and save to storage
  Future<void> login({
    required String userId,
    required String token,
    required String email,
  }) async {
    _userId = userId;
    _token = token;
    _email = email;

    // SAVE DATA TO STORAGE
    await _storage.write(key: 'userId', value: userId);
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'email', value: email);

    notifyListeners();
  }

  // ✅ 4. Make this 'async' and clear storage on logout
  Future<void> logout() async {
    _userId = null;
    _token = null;
    _email = null;

    // CLEAR DATA FROM STORAGE
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');

    notifyListeners();
  }

  bool get isLoggedIn => _userId != null;
  
  // Optional: Add a check to load user on app startup
  Future<void> tryAutoLogin() async {
    final storedId = await _storage.read(key: 'userId');
    final storedToken = await _storage.read(key: 'token');
    final storedEmail = await _storage.read(key: 'email');

    if (storedId != null && storedToken != null) {
      _userId = storedId;
      _token = storedToken;
      _email = storedEmail;
      notifyListeners();
    }
  }
}