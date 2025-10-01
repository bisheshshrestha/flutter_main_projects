import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/services/database.dart';
import 'admin_home.dart';

class AdminReedem extends StatefulWidget {
  const AdminReedem({super.key});

  @override
  State<AdminReedem> createState() => _AdminReedemState();
}

class _AdminReedemState extends State<AdminReedem> {
  Stream? redeemStream;

  @override
  void initState() {
    super.initState();
    loadRedeemRequests();
  }

  Future<void> loadRedeemRequests() async {
    redeemStream = await DatabaseMethods().getAdminReedemApproval();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient AppBar
      appBar: AppBar(
        title: const Text("Redeem Requests",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHome()),
            );
          },
        ),
      ),

      // Body
      body: redeemStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: redeemStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
            return const Center(child: Text("No redeem requests available."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data.docs[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Badge
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doc["Date"],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Name
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            doc["Name"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Points
                      Row(
                        children: [
                          const Icon(Icons.point_of_sale, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "Points: ${doc["Points"]}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Esewa ID
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            "Esewa ID: ${doc["Esewa ID"]}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Approve Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await DatabaseMethods().updateAdminReedemRequests(doc.id);
                            await DatabaseMethods().updateUserReedemRequests(doc["User ID"], doc.id);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Request Approved")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          label: const Text(
                            "Approve",
                            style: TextStyle(fontSize: 16,color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
