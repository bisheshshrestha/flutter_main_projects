import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_approval.dart';
import 'package:recycle_mate/Admin/admin_reedem.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Admin Panel",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AdminCard(
                    imagePath: "assets/images/approval.png",
                    label: "Approval",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> AdminApproval()));
                    },
                  ),
                  _AdminCard(
                    imagePath: "assets/images/reedem.png",
                    label: "Redeem",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> AdminReedem()));
                    },
                  ),
                ],
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.0),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 90,
                width: 90,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 18),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}