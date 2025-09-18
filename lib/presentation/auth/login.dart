import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ozvol_customer/core/sessio_manager.dart';
import 'package:ozvol_customer/utils/colors.dart';
import 'package:ozvol_customer/presentation/home.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  _CustomerLoginPageState createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final CollectionReference authRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  final SessionManager _session = SessionManager();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _checkLoggedInUser();
  }

  /// 🔹 Check session on app start
  void _checkLoggedInUser() async {
    final session = await _session.getSession();
    final docId = session['docId'];

    if (docId != null) {
      final docSnapshot = await authRef.doc(docId).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;

        final bool active = userData['active'] ?? false;
        final bool isLoggedIn = userData['isLoggedIn'] ?? false;

        if (active && isLoggedIn) {
          // ✅ attach listener only if valid
          _session.attachListener(docId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CustomerHomePage(userData: {...userData, 'docId': docId}),
            ),
          );
        } else {
          // 🚫 session expired -> logout
          await _session.clearSession();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
          );
        }
      } else {
        await _session.clearSession();
      }
    }
  }

  /// 🔹 Save FCM Token after login
  Future<void> _saveFcmToken(String docId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await authRef.doc(docId).update({'fcmToken': token});
        print("✅ Token saved for $docId");
      }

      // 🔄 Keep listening for refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await authRef.doc(docId).update({'fcmToken': newToken});
        print("🔄 Token refreshed for $docId");
      });
    } catch (e) {
      print("⚠️ Error saving FCM token: $e");
    }
  }

  /// 🔹 Login method
  /// 🔹 Login method
  void _login() async {
    setState(() => loading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    final query = await authRef
        .where('name', isEqualTo: email)
        .where('password', isEqualTo: password)
        .get();

    if (query.docs.isNotEmpty) {
      final userDoc = query.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;

      if (userData['active'] == true) {
        // ✅ Force logout other sessions first
        await userDoc.reference.update({
          'isLoggedIn': false,
          'fcmToken': FieldValue.delete(), // remove old device token
        });

        // Small delay to ensure old device listener triggers
        await Future.delayed(const Duration(milliseconds: 300));

        // ✅ Allow current device to login
        await userDoc.reference.update({'isLoggedIn': true});

        await _session.saveSession(email, userDoc.id);
        _session.attachListener(userDoc.id);

        // 🔹 Save token now
        await _saveFcmToken(userDoc.id);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CustomerHomePage(userData: {...userData, 'docId': userDoc.id}),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your account is not active")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withOpacity(.8),
          content: const Text("Invalid credentials"),
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kprimerycolor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Customer Login",
              style: TextStyle(
                fontSize: 21,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Name",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            loading
                ? CircularProgressIndicator(color: kseccolor)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kseccolor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
