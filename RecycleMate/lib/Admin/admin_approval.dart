import 'package:flutter/material.dart';
import 'package:recycle_mate/services/widget_support.dart';

class AdminApproval extends StatefulWidget {
  const AdminApproval({super.key});

  @override
  State<AdminApproval> createState() => _AdminApprovalState();
}

class _AdminApprovalState extends State<AdminApproval> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  Material(
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFececf8),
                        size: 30.0,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 5),
                  Text("Upload Item", style: AppWidget.headlineTextStyle(25.0)),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  // color: Color(0xFFececf8),
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // You can add widgets here
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
