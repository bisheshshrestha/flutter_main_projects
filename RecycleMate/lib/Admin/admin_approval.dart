import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_home.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/widget_support.dart';

class AdminApproval extends StatefulWidget {
  const AdminApproval({super.key});

  @override
  State<AdminApproval> createState() => _AdminApprovalState();
}

class _AdminApprovalState extends State<AdminApproval> {
  Stream? approvalStream;

  @override
  void initState() {
    super.initState();
    getApprovalStream();
  }

  Future<void> getApprovalStream() async {
    approvalStream = await DatabaseMethods().getAdminApproval();
    setState(() {});
  }

  Future<int> _getUserPointsSafe(String docId) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      if (!snap.exists) return 0;
      final data = (snap.data() as Map<String, dynamic>?);
      final p = data?['points'];
      if (p == null) return 0;
      if (p is int) return p;
      if (p is double) return p.round();
      if (p is String) return int.tryParse(p) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // Compute points to award using either EstimatedPoints or by rules
  int _computeAwardPoints(Map<String, dynamic> data) {
    // 1) If EstimatedPoints is present and valid, prefer it
    final est = data['EstimatedPoints'];
    if (est is int && est >= 0) return est;
    if (est is double && est >= 0) return est.round();
    if (est is String) {
      final parsed = double.tryParse(est);
      if (parsed != null && parsed >= 0) return parsed.round();
    }

    // 2) Else compute from Category + Quantity (+ QuantityUnit if provided)
    final category = (data['Category'] ?? '').toString().toLowerCase();
    final unit = (data['QuantityUnit'] ?? '').toString().toLowerCase(); // 'piece' or 'kg' if present
    final qRaw = data['Quantity'];

    // Parse quantity as double for flexibility
    double qty = 0;
    if (qRaw is int) qty = qRaw.toDouble();
    else if (qRaw is double) qty = qRaw;
    else if (qRaw is String) qty = double.tryParse(qRaw) ?? 0;

    // Determine rate
    bool isPlastic = category.contains('plastic'); // covers "Plastic Bottle"
    double rate;
    if (isPlastic) {
      rate = 2; // per piece
      // ensure whole pieces
      qty = qty.floorToDouble();
    } else if (category.contains('paper')) {
      rate = 10; // per kg
    } else {
      rate = 20; // default to glass rule (20 per kg)
    }

    // If unit is provided, respect it; otherwise rely on category
    if (unit == 'piece') {
      qty = qty.floorToDouble();
    }

    final pts = (rate * qty).round();
    return pts < 0 ? 0 : pts;
  }

  Widget allApprovals() {
    return StreamBuilder(
      stream: approvalStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            final DocumentSnapshot ds = snapshot.data.docs[index];
            final Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
            final int awardPoints = _computeAwardPoints(data);

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
                        child: (data["Image"] != null && data["Image"].toString().isNotEmpty)
                            ? Image.network(
                          data["Image"],
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
                            // Name
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.green, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    (data["Name"] ?? "-").toString(),
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0),

                            // Address
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.green, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    (data["Address"] ?? "-").toString(),
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0),

                            // Quantity (+ unit if available)
                            Row(
                              children: [
                                const Icon(Icons.inventory, color: Colors.green, size: 28.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    data["QuantityUnit"] != null
                                        ? "${data["Quantity"]} ${data["QuantityUnit"]}"
                                        : data["Quantity"].toString(),
                                    style: AppWidget.normalTextStyle(20.0),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6.0),

                            // Estimated points display
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.amber, size: 24.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  "Est. Points: $awardPoints",
                                  style: AppWidget.headlineTextStyle(18.0),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10.0),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      // Calculate points to award
                                      final pointsToAdd = awardPoints;

                                      // Get current user points safely
                                      final current = await _getUserPointsSafe(data["UserId"]);

                                      final updatedPoints = current + pointsToAdd;

                                      await DatabaseMethods()
                                          .updateUserPoints(data["UserId"], updatedPoints.toString());

                                      // Optionally store awarded points on the admin/user item docs for audit
                                      // await DatabaseMethods().setAwardedPointsOnDocs(data["UserId"], ds.id, pointsToAdd);

                                      await DatabaseMethods().updateAdminRequests(ds.id); // set Status = Approved
                                      await DatabaseMethods().updateUserRequests(data["UserId"], ds.id);

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Request Approved (+$pointsToAdd pts)")),
                                      );
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Approve",
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
                                      await DatabaseMethods().rejectAdminRequest(ds.id);
                                      await DatabaseMethods().rejectUserRequest(data["UserId"], ds.id);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Request Rejected")),
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
                                          "Reject",
                                          style: AppWidget.whiteTextStyle(18.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminHome()));
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
                      "Admin Approval",
                      style: AppWidget.headlineTextStyle(25.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // List of dynamic approval cards
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
                child: allApprovals(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}