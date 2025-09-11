import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ozvol_customer/presentation/auth/login.dart';
import 'package:ozvol_customer/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerHomePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  CustomerHomePage({required this.userData});
  final CollectionReference stocksRef = FirebaseFirestore.instance.collection(
    'stocks',
  );
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'customers',
  );

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
                      userData['name'],
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
              logout(userData['name'], context);
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
          "Welcome, ${userData['name'] ?? 'User'}",
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

              return Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                decoration: BoxDecoration(
                  color: kseccolor.withOpacity(.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: double.infinity,

                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock['stockName'] ?? 'Stock Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        Text(
                          stock['action'] ?? '-',
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                (stock['action'] == 'buy' ||
                                    stock['action'] == 'Buy')
                                ? Colors.blue
                                : (stock['action'] == 'sell' ||
                                      stock['action'] == 'Sell')
                                ? Colors.green
                                : (stock['action'] == 'exit' ||
                                      stock['action'] == 'Exit')
                                ? Colors.red
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            // optional to highlight
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),
                    // Text(
                    //   'Price: \$${stock['price'] ?? '-'}',
                    //   style: TextStyle(fontSize: 18),
                    // ),
                    SizedBox(height: 10),
                    Text(
                      'SL:  ${stock['sl'] ?? '-'}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'TGT 1: ${stock['tgt1'] ?? '-'}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'TGT 2: ${stock['tgt2'] ?? '-'}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'TGT 3: ${stock['tgt3'] ?? '-'}',
                      style: TextStyle(fontSize: 18),
                    ),
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
