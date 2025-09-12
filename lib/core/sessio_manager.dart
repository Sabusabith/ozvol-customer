import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:ozvol_customer/main.dart'; // ✅ import for navigatorKey

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final CollectionReference _authRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  StreamSubscription<DocumentSnapshot>? _userListener;

  /// Save session
  Future<void> saveSession(String email, String docId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('docId', docId);
  }

  /// Get session
  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'docId': prefs.getString('docId'),
    };
  }

  /// Clear session + cancel listener
  Future<void> clearSession() async {
    await _userListener?.cancel();
    _userListener = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 🔹 Global Firestore listener for account deactivation or force logout
  void attachListener(String docId) {
    _userListener?.cancel();
    _userListener = _authRef.doc(docId).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final bool active = data['active'] ?? true;
      final bool isLoggedIn = data['isLoggedIn'] ?? true;

      if (!active || !isLoggedIn) {
        await clearSession();

        // 🔥 Navigate globally without needing BuildContext
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CustomerLoginPage()),
          (route) => false,
        );

        // Show red snackbar
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

  /// Logout manually
  Future<void> logout(String docId, BuildContext context) async {
    try {
      await _authRef.doc(docId).update({'isLoggedIn': false});
    } catch (_) {}
    await clearSession();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CustomerLoginPage()),
      (route) => false,
    );
  }
}
