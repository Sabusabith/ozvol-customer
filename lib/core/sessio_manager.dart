import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:ozvol_customer/main.dart'; // navigatorKey

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final CollectionReference _authRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  StreamSubscription<DocumentSnapshot>? _userListener;
  bool _manualLogout = false;

  /// Save session with deviceId
  Future<void> saveSession(String email, String docId, String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('docId', docId);
    await prefs.setString('deviceId', deviceId);
  }

  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'docId': prefs.getString('docId'),
      'deviceId': prefs.getString('deviceId'),
    };
  }

  Future<void> clearSession() async {
    await _userListener?.cancel();
    _userListener = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void attachListener(String docId) {
    _userListener?.cancel();
    _userListener = _authRef.doc(docId).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final bool active = data['active'] ?? true;
      final bool isLoggedIn = data['isLoggedIn'] ?? true;
      final String? currentDeviceId = data['currentDeviceId'];

      final session = await getSession();
      final String? deviceId = session['deviceId'];

      if (_manualLogout) {
        _manualLogout = false;
        return;
      }

      // Logout if account inactive or another device logged in
      if (!active || !isLoggedIn || currentDeviceId != deviceId) {
        await clearSession();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
          (route) => false,
        );

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                !active
                    ? "Your account has been deactivated by admin."
                    : "You have been logged out (another device logged in).",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> logout(String docId, BuildContext context) async {
    try {
      _manualLogout = true;
      await _authRef.doc(docId).update({
        'isLoggedIn': false,
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
    await clearSession();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
      (route) => false,
    );

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text("You have logged out successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
