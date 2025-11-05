import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();
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
    final unit = (data['QuantityUnit'] ?? '')
        .toString()
        .toLowerCase(); // 'piece' or 'kg' if present
    final qRaw = data['Quantity'];

    // Parse quantity as double for flexibility
    double qty = 0;
    if (qRaw is int) {
      qty = qRaw.toDouble();
    } else if (qRaw is double) {
      qty = qRaw;
    } else if (qRaw is String) {
      qty = double.tryParse(qRaw) ?? 0;
    }

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

        if (snapshot.data.docs.length == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            final DocumentSnapshot ds = snapshot.data.docs[index];
            final Map<String, dynamic> data =
            ds.data() as Map<String, dynamic>;
            final int awardPoints = _computeAwardPoints(data);

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image and basic info row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: (data["Image"] != null &&
                                data["Image"].toString().isNotEmpty)
                                ? Image.network(
                              data["Image"],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              "assets/images/coca.png",
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      (data["Name"] ?? "-").toString(),
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),

                              // Category
                              if (data["Category"] != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.blue,
                                      size: 18.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        data["Category"].toString(),
                                        style: const TextStyle(fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6.0),

                              // Quantity
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory,
                                    color: Colors.orange,
                                    size: 18.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      data["QuantityUnit"] != null
                                          ? "${data["Quantity"]} ${data["QuantityUnit"]}"
                                          : data["Quantity"].toString(),
                                      style: const TextStyle(fontSize: 14.0),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            (data["Address"] ?? "-").toString(),
                            style: const TextStyle(fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    // Estimated points display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.amber,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "Estimated Points: $awardPoints",
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Action Buttons
                    Row(
                      children: [
                        // Approve Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Calculate points to award
                              final pointsToAdd = awardPoints;

                              // Get current user points safely
                              final current =
                              await _getUserPointsSafe(data["UserId"]);

                              final updatedPoints = current + pointsToAdd;

                              await DatabaseMethods().updateUserPoints(
                                  data["UserId"], updatedPoints.toString());

                              await DatabaseMethods()
                                  .updateAdminRequests(ds.id);
                              await DatabaseMethods()
                                  .updateUserRequests(data["UserId"], ds.id);

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Request Approved (+$pointsToAdd pts)"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle, size: 20),
                            label: const Text("Approve"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12.0),

                        // Reject Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await DatabaseMethods().rejectAdminRequest(ds.id);
                              await DatabaseMethods()
                                  .rejectUserRequest(data["UserId"], ds.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Request Rejected"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            icon: const Icon(Icons.cancel, size: 20),
                            label: const Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      appBar: AppBar(
        title: const Text('Admin Approval'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 251, 251, 251),
        ),
        child: allApprovals(),
      ),
    );
  }
}
