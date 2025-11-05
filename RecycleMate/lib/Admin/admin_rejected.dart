import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Future<String> getUserPoints(String docId) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        return data['points'].toString();
      } else {
        return 'No document';
      }
    } catch (e) {
      return 'Error';
    }
  }

  void _showDeleteConfirmDialog(DocumentSnapshot ds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to permanently delete this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
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

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Request deleted permanently"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget allRejected() {
    return StreamBuilder(
      stream: rejectedStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (snapshot.data.docs.isEmpty) {
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
                  'No rejected requests',
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
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            final Map<String, dynamic> data =
            ds.data() as Map<String, dynamic>;

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
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/coca.png",
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                );
                              },
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
                                    color: Colors.red,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      data["Name"] ?? "-",
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
                          color: Colors.redAccent,
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            data["Address"] ?? "-",
                            style: const TextStyle(fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    // Rejected Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: Colors.red[700], size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "REJECTED",
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Action Buttons
                    Row(
                      children: [
                        // Reopen Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Move back to pending status
                              await FirebaseFirestore.instance
                                  .collection("requests")
                                  .doc(ds.id)
                                  .update({"Status": "Pending"});

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(data["UserId"])
                                  .collection("items")
                                  .doc(ds.id)
                                  .update({"Status": "Pending"});

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Request moved to Pending"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Reopen"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12.0),

                        // Delete Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteConfirmDialog(ds),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text("Delete"),
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
        title: const Text('Rejected Requests'),
        backgroundColor: Colors.red[700],
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
        child: allRejected(),
      ),
    );
  }
}
