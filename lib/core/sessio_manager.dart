import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final CollectionReference _authRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  StreamSubscription<DocumentSnapshot>? _userListener;

  /// 🔹 Save login session
  Future<void> saveSession(String email, String docId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('docId', docId);
  }

  /// 🔹 Clear session & stop listener
  Future<void> clearSession() async {
    _userListener?.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// 🔹 Attach Firestore listener (always listen for changes)
  void attachListener(BuildContext context, String docId) {
    _userListener?.cancel(); // avoid duplicates
    _userListener = _authRef.doc(docId).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;

        if (userData['active'] == false || userData['isLoggedIn'] == false) {
          await clearSession();

          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => CustomerLoginPage()),
              (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  userData['active'] == false
                      ? "Your account has been deactivated by admin."
                      : "You have been logged out (another device logged in).",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  /// 🔹 Logout manually
  Future<void> logout(BuildContext context, String docId) async {
    await _authRef.doc(docId).update({'isLoggedIn': false});
    await clearSession();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => CustomerLoginPage()),
        (route) => false,
      );
    }
  }

  /// 🔹 Get current session
  Future<Map<String, String?>> getSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'docId': prefs.getString('docId'),
    };
  }
}
