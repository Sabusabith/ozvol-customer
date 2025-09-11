import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ozvol_customer/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozvol_customer/presentation/home.dart';

class CustomerLoginPage extends StatefulWidget {
  @override
  _CustomerLoginPageState createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final CollectionReference authRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  bool loading = false;
  Stream<DocumentSnapshot>? userStream; // 👈 will store listener

  @override
  void initState() {
    super.initState();
    checkLoggedInUser();
  }

  /// Attach a Firestore listener to auto logout if admin deactivates account
  void attachUserListener(String docId) {
    userStream = authRef.doc(docId).snapshots();
    userStream!.listen((snapshot) async {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        if (userData['active'] == false || userData['isLoggedIn'] == false) {
          // 👈 Logout immediately
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => CustomerLoginPage()),
              (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Your account has been deactivated by admin."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  /// Check if user is already logged in on this device
  void checkLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? docId = prefs.getString('docId');

    if (email != null && docId != null) {
      final query = await authRef.where('name', isEqualTo: email).get();

      if (query.docs.isNotEmpty) {
        final userDoc = query.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData['active'] == true && userData['isLoggedIn'] == true) {
          // ✅ Attach listener
          attachUserListener(userDoc.id);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerHomePage(userData: userData),
            ),
          );
        } else {
          await prefs.clear();
        }
      }
    }
  }

  /// Login method
  void login() async {
    setState(() {
      loading = true;
    });

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
        if (userData['isLoggedIn'] == true) {
          // Already logged in on another device
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.withOpacity(.3),
              content: Text(
                "This account is already logged in on another device",
              ),
            ),
          );
        } else {
          // Mark user as logged in
          await userDoc.reference.update({'isLoggedIn': true});

          // Save user locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('docId', userDoc.id);

          // ✅ Attach listener
          attachUserListener(userDoc.id);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerHomePage(userData: userData),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Your account is not active")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withOpacity(.3),
          content: Text("Invalid credentials"),
        ),
      );
    }

    setState(() {
      loading = false;
    });
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
            Text(
              "Customer Login",
              style: TextStyle(
                fontSize: 21,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              style: TextStyle(color: Colors.white),
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
            SizedBox(height: 12),
            TextField(
              style: TextStyle(color: Colors.white),
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
            SizedBox(height: 24),
            loading
                ? CircularProgressIndicator(color: kseccolor)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kseccolor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: login,
                    child: Text("Login", style: TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
