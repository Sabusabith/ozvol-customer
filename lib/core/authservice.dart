import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/auth/login.dart';

class AuthService {
  static Stream<DocumentSnapshot>? _userStream;

  /// Starts a listener for the logged-in customer
  static Future<void> startUserListener(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? docId = prefs.getString('docId');

    if (docId != null) {
      _userStream = FirebaseFirestore.instance
          .collection('customers')
          .doc(docId)
          .snapshots();

      _userStream!.listen((snapshot) async {
        if (snapshot.exists) {
          final userData = snapshot.data() as Map<String, dynamic>;
          bool isActive = userData['active'] ?? true;
          bool isLoggedIn = userData['isLoggedIn'] ?? true;

          if (!isActive || !isLoggedIn) {
            // Clear stored data
            await prefs.clear();

            // Navigate to login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => CustomerLoginPage()),
              (route) => false,
            );

            // Show message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Your account has been deactivated or logged out.",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }
}
