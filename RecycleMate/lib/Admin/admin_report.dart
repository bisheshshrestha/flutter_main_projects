import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReport extends StatefulWidget {
  const AdminReport({super.key});

  @override
  State<AdminReport> createState() => _AdminReportState();
}

class _AdminReportState extends State<AdminReport> {
  int totalRequests = 0;
  int approvedRequests = 0;
  int rejectedRequests = 0;
  int pendingRequests = 0;
  int totalPointsRedeemed = 0;
  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      // Get all user requests (items)
      QuerySnapshot itemsSnapshot = await _firestore.collectionGroup('items').get();
      List<DocumentSnapshot> items = itemsSnapshot.docs;

      int total = items.length;
      int approved = 0;
      int rejected = 0;
      int pending = 0;

      for (var item in items) {
        final data = item.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('Status')) {
          String status = data['Status'] ?? 'Pending';

          switch (status) {
            case 'Approved':
              approved++;
              break;
            case 'Rejected':
              rejected++;
              break;
            default:
              pending++;
              break;
          }
        } else {
          pending++;
        }
      }

      // Get total redeemed points
      QuerySnapshot redeemSnapshot = await _firestore.collectionGroup('redeem').get();
      int points = 0;
      for (var doc in redeemSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['Points'] is num) {
          points += (data['Points'] as num).toInt();
        }
      }

      if (!mounted) return;
      setState(() {
        totalRequests = total;
        approvedRequests = approved;
        rejectedRequests = rejected;
        pendingRequests = pending;
        totalPointsRedeemed = points;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Report'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSummaryCard('Total', totalRequests, Colors.blue),
                const SizedBox(width: 10),
                _buildSummaryCard('Points', totalPointsRedeemed, Colors.amber),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Request Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatusCard('Approved', approvedRequests, Colors.green, Icons.check_circle),
            const SizedBox(height: 10),
            _buildStatusCard('Pending', pendingRequests, Colors.orange, Icons.pending),
            const SizedBox(height: 10),
            _buildStatusCard('Rejected', rejectedRequests, Colors.red, Icons.cancel),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchReportData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
              Text(title, style: TextStyle(fontSize: 16, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }
}
