import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_approval.dart';
import 'package:recycle_mate/Admin/admin_reedem.dart';
import 'package:recycle_mate/Admin/admin_rejected.dart';
import 'package:recycle_mate/Admin/admin_login.dart';
import 'package:recycle_mate/services/auth.dart';
import 'package:recycle_mate/services/shared_pref.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Future<void> _logout() async {
    try {
      await AuthMethods().SignOut();
      await SharedPreferenceHelper().clearAll();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLogin()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _logout(); }, child: const Text('Logout')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _confirmLogout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // 2 per row grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _AdminCard(
                      imagePath: "assets/images/approval.png",
                      label: "Approval",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApproval()));
                      },
                    ),
                    _AdminCard(
                      imagePath: "assets/images/reedem.png",
                      label: "Redeem",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReedem()));
                      },
                    ),
                    _AdminCard(
                      imagePath: "assets/images/rejected.png",
                      label: "Rejected",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRejected()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _AdminCard({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 90, width: 90, fit: BoxFit.contain),
            const SizedBox(height: 18),
            Text(
              label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green[800]),
            ),
          ],
        ),
      ),
    );
  }
}