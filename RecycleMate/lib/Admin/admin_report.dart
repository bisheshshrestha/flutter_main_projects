import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReport extends StatefulWidget {
  const AdminReport({super.key});

  @override
  State<AdminReport> createState() => _AdminReportState();
}

class _AdminReportState extends State<AdminReport> {
  // Overall statistics
  int totalRequests = 0;
  int approvedRequests = 0;
  int rejectedRequests = 0;
  int pendingRequests = 0;
  int totalPointsRedeemed = 0;
  int totalUsersSubmitted = 0;

  // Recyclable waste categories - UPDATED
  Map<String, int> wasteCategoryCount = {
    'Plastic Bottle': 0,
    'Paper': 0,
    'Glass': 0,
    'Cardboard': 0,
    'Metal': 0,
    'Others': 0,
  };

  // User-specific data
  List<Map<String, dynamic>> topUsers = [];

  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => isLoading = true);

    try {
      // Get all user requests (items) from all users
      QuerySnapshot itemsSnapshot = await _firestore.collectionGroup('items').get();
      List<DocumentSnapshot> items = itemsSnapshot.docs;

      int total = items.length;
      int approved = 0;
      int rejected = 0;
      int pending = 0;

      // Reset category counts - UPDATED
      wasteCategoryCount = {
        'Plastic Bottle': 0,
        'Paper': 0,
        'Glass': 0,
        'Cardboard': 0,
        'Metal': 0,
        'Others': 0,
      };

      // User contribution tracking
      Map<String, Map<String, dynamic>> userContributions = {};

      for (var item in items) {
        final data = item.data() as Map<String, dynamic>?;

        if (data != null) {
          // Count status
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

          // Count waste categories - UPDATED
          String category = data['Category'] ?? 'Others';
          if (wasteCategoryCount.containsKey(category)) {
            wasteCategoryCount[category] = wasteCategoryCount[category]! + 1;
          } else {
            wasteCategoryCount['Others'] = wasteCategoryCount['Others']! + 1;
          }

          // Track user contributions
          String userName = data['Name'] ?? 'Unknown User';
          String userEmail = data['Email'] ?? '';

          if (!userContributions.containsKey(userEmail)) {
            userContributions[userEmail] = {
              'name': userName,
              'email': userEmail,
              'count': 0,
              'points': 0,
            };
          }
          userContributions[userEmail]!['count'] =
              (userContributions[userEmail]!['count'] as int) + 1;
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

          // Track points per user
          String userEmail = data['Email'] ?? '';
          if (userContributions.containsKey(userEmail)) {
            userContributions[userEmail]!['points'] =
                (userContributions[userEmail]!['points'] as int) +
                    (data['Points'] as num).toInt();
          }
        }
      }

      // Sort users by contribution count
      List<Map<String, dynamic>> sortedUsers = userContributions.values.toList();
      sortedUsers.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      if (!mounted) return;
      setState(() {
        totalRequests = total;
        approvedRequests = approved;
        rejectedRequests = rejected;
        pendingRequests = pending;
        totalPointsRedeemed = points;
        totalUsersSubmitted = userContributions.length;
        topUsers = sortedUsers.take(10).toList(); // Top 10 users
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecycleMate Admin Report'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReportData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Overview Section
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSummaryCard('Total Requests', totalRequests, Colors.blue, Icons.inventory),
                const SizedBox(width: 10),
                _buildSummaryCard('Active Users', totalUsersSubmitted, Colors.purple, Icons.people),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSummaryCard('Points Earned', totalPointsRedeemed, Colors.amber, Icons.star),
                const SizedBox(width: 10),
                _buildSummaryCard('Pending', pendingRequests, Colors.orange, Icons.pending),
              ],
            ),

            const SizedBox(height: 30),

            // Request Status Section
            const Text(
              'Request Status Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatusCard('Approved', approvedRequests, Colors.green, Icons.check_circle),
            const SizedBox(height: 10),
            _buildStatusCard('Pending', pendingRequests, Colors.orange, Icons.pending),
            const SizedBox(height: 10),
            _buildStatusCard('Rejected', rejectedRequests, Colors.red, Icons.cancel),

            const SizedBox(height: 30),

            // Waste Category Section
            const Text(
              'Recyclable Waste by Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...wasteCategoryCount.entries.map((entry) {
              if (entry.value > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCategoryCard(
                    entry.key,
                    entry.value,
                    _getCategoryColor(entry.key),
                    _getCategoryIcon(entry.key),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),

            const SizedBox(height: 30),

            // Top Contributing Users Section
            const Text(
              'Top Contributing Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (topUsers.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No user contributions yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              ...topUsers.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> user = entry.value;
                return _buildUserCard(
                  index + 1,
                  user['name'] ?? 'Unknown',
                  user['email'] ?? '',
                  user['count'] ?? 0,
                  user['points'] ?? 0,
                );
              }).toList(),

            const SizedBox(height: 30),

            // Refresh Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchReportData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category, int count, Color color, IconData icon) {
    double percentage = totalRequests > 0 ? (count / totalRequests) * 100 : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of total',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(int rank, String name, String email, int requests, int points) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getRankColor(rank), _getRankColor(rank).withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: rank <= 3
                ? Icon(
              rank == 1
                  ? Icons.emoji_events
                  : rank == 2
                  ? Icons.military_tech
                  : Icons.workspace_premium,
              color: Colors.white,
              size: 24,
            )
                : Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.recycling, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text('$requests requests',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                '$points',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Colors for your waste categories
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Plastic Bottle':
        return Colors.blue;
      case 'Paper':
        return Colors.brown;
      case 'Glass':
        return Colors.cyan;
      case 'Cardboard':
        return Colors.orange;
      case 'Metal':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  // UPDATED: Icons for your waste categories
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Plastic Bottle':
        return Icons.water_drop;
      case 'Paper':
        return Icons.description;
      case 'Glass':
        return Icons.local_drink;
      case 'Cardboard':
        return Icons.archive;
      case 'Metal':
        return Icons.settings;
      default:
        return Icons.category;
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.green;
  }
}
