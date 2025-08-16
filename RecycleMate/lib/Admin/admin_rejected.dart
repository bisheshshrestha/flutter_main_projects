import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_home.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/widget_support.dart';

class AdminRejected extends StatefulWidget {
  const AdminRejected({super.key});

  @override
  State<AdminRejected> createState() => _AdminRejectedState();
}

class _AdminRejectedState extends State<AdminRejected> {
  Stream? rejectedStream;

  getRejectedStream() async {
    rejectedStream = await FirebaseFirestore.instance
        .collection("requests")
        .where("Status", isEqualTo: "Rejected")
        .snapshots();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getRejectedStream();
  }

  Future<String> getUserPoints(String docId) async{
    try{
      //Reference to the 'users' collection and specific document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if(docSnapshot.exists){
        //Get the 'userpoints' field
        var data = docSnapshot.data() as Map<String, dynamic>;
        return data['points'].toString();
      }else{
        print('No such document!');
        return 'No document';
      }
    }catch(e){
      print("Error fetching user points! $e");
      return 'Error';
    }
  }

  Widget allRejected() {
    return StreamBuilder(
      stream: rejectedStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.docs.isEmpty) {
          return const Center(
            child: Text(
              "No rejected requests",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Material(
                elevation: 3.0,
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: ds["Image"] != "" ?
                        Image.network(
                          ds["Image"],
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                        )
                            : Image.asset(
                          "assets/images/coca.png",
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.red, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    ds["Name"],
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    ds["Address"],
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.inventory, color: Colors.red, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    ds["Quantity"].toString(),
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      // Move back to pending status
                                      await FirebaseFirestore.instance
                                          .collection("requests")
                                          .doc(ds.id)
                                          .update({"Status": "Pending"});

                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(ds["UserId"])
                                          .collection("items")
                                          .doc(ds.id)
                                          .update({"Status": "Pending"});

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Request moved to Pending")),
                                      );
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Reopen",
                                          style: AppWidget.whiteTextStyle(18.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      // Delete permanently
                                      await FirebaseFirestore.instance
                                          .collection("requests")
                                          .doc(ds.id)
                                          .delete();
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(ds["UserId"])
                                          .collection("items")
                                          .doc(ds.id)
                                          .delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Request deleted permanently")),
                                      );
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Delete",
                                          style: AppWidget.whiteTextStyle(18.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: const Text(
                                "REJECTED",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> const AdminHome()));
                    },
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFececf8),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 7),
                  Expanded(
                    child: Text(
                      "Rejected Requests",
                      style: AppWidget.headlineTextStyle(25.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // List of rejected requests
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 251, 251, 251),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: allRejected(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}