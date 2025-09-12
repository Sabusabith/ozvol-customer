import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ozvol_customer/core/sessio_manager.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:ozvol_customer/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CustomerHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  CustomerHomePage({required this.userData});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final CollectionReference stocksRef = FirebaseFirestore.instance.collection(
    'stocks',
  );

  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'customers',
  );

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    registerToken(widget.userData['docId']);
  }

  Future<void> registerToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .update({
            'fcmToken': token,
            'isLoggedIn': true, // mark user as logged in
          });
      print("✅ FCM token registered for user $userId");
    }
  }

  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("✅ Notification permission granted");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint("⚠️ Provisional notification permission granted");
    } else {
      debugPrint("❌ Notification permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shape: Border(),
        width: MediaQuery.of(context).size.width / 2.5,
        backgroundColor: kprimerycolor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(
                      CupertinoIcons.person_alt_circle,
                      size: 45,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.userData['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final sess = await SessionManager().getSession();
                final docId = sess['docId'];
                if (docId != null) {
                  // Call the logout method from SessionManager
                  await SessionManager().logout(docId, context);
                }
              },
              child: Icon(Icons.logout, color: Colors.white, size: 35),
            ),
          ],
        ),
      ),
      backgroundColor: kprimerycolor,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: kseccolor, // Set your desired color
          size: 28, // Optional: change size
        ),
        backgroundColor: kprimerycolor,
        title: Text(
          "Welcome, ${widget.userData['name'] ?? 'User'}",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          // ---------------- Stock Info on Top ----------------
          StreamBuilder<QuerySnapshot>(
            stream: stocksRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: kseccolor),
                );

              final stocks = snapshot.data!.docs;
              if (stocks.isEmpty)
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No stocks available"),
                );

              // Displaying only the first stock as example
              var stock = stocks[0].data() as Map<String, dynamic>;
              Timestamp? timestamp = stock['statusUpdatedAt'] as Timestamp?;
              String formattedDate = timestamp != null
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp.toDate())
                  : "N/A";

              return Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                decoration: BoxDecoration(
                  color: kseccolor.withOpacity(.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: double.infinity,

                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      stock['stockName'] ?? 'Stock Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stock['action'] ?? '-',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                (stock['action'] == 'buy' ||
                                    stock['action'] == 'Buy')
                                ? Colors.green
                                : (stock['action'] == 'sell' ||
                                      stock['action'] == 'Sell')
                                ? Colors.red
                                : (stock['action'] == 'exit' ||
                                      stock['action'] == 'Exit')
                                ? Colors.blue
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            // optional to highlight
                          ),
                        ),
                      ],
                    ),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,

                    //   children: [
                    //     Text(
                    //       'Time: ',
                    //       style: TextStyle(
                    //         fontSize: 18,
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),

                    //     Text(
                    //       formattedDate,
                    //       style: TextStyle(color: Colors.grey.shade400),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 4),
                    // Text(
                    //   'Price: \$${stock['price'] ?? '-'}',
                    //   style: TextStyle(fontSize: 18),
                    // ),
                    SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 10),
          //2nd stream
          StreamBuilder<QuerySnapshot>(
            stream: stocksRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: kseccolor),
                );

              final stocks = snapshot.data!.docs;
              if (stocks.isEmpty)
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No stocks available"),
                );

              // Displaying only the first stock as example
              var stock = stocks[0].data() as Map<String, dynamic>;
              Timestamp? timestamp = stock['targetsUpdatedAt'] as Timestamp?;
              String formattedDate = timestamp != null
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp.toDate())
                  : "N/A";

              return Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                decoration: BoxDecoration(
                  color: kseccolor.withOpacity(.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: double.infinity,

                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 4),
                    // Text(
                    //   'Price: \$${stock['price'] ?? '-'}',
                    //   style: TextStyle(fontSize: 18),
                    // ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SL: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stock['sl'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TGT 1: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stock['tgt1'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TGT 2: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stock['tgt2'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TGT 3: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stock['tgt3'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,

                    //   children: [
                    //     Text(
                    //       'Time: ',
                    //       style: TextStyle(
                    //         fontSize: 18,
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),

                    //     Text(
                    //       formattedDate,
                    //       style: TextStyle(color: Colors.grey.shade400),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 16),

          // ---------------- Customers List at Bottom ----------------
          // Expanded(
          //   child: StreamBuilder<QuerySnapshot>(
          //     stream: usersRef.snapshots(),
          //     builder: (context, snapshot) {
          //       if (!snapshot.hasData)
          //         return Center(
          //           child: CircularProgressIndicator(color: kseccolor),
          //         );

          //       final users = snapshot.data!.docs;

          //       if (users.isEmpty)
          //         return Center(child: Text("No customers found"));

          //       return ListView.builder(
          //         itemCount: users.length,
          //         itemBuilder: (context, index) {
          //           var user = users[index].data() as Map<String, dynamic>;
          //           return ListTile(
          //             leading: CircleAvatar(
          //               child: Text(user['name'][0].toUpperCase()),
          //             ),
          //             title: Text(
          //               user['name'] ?? 'Unnamed',
          //               style: TextStyle(color: Colors.white),
          //             ),
          //             subtitle: Text(
          //               'ID: ${users[index].id}',
          //               style: TextStyle(color: Colors.grey.shade500),
          //             ),
          //           );
          //         },
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  //logout
  Future<void> logout(String email, BuildContext context) async {
    final query = await FirebaseFirestore.instance
        .collection('customers')
        .where('name', isEqualTo: email)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({'isLoggedIn': false});
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CustomerLoginPage()),
    );
  }
}
