import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_approval.dart';
import 'package:recycle_mate/Admin/admin_reedem.dart';
import 'package:recycle_mate/pages/bottomnav.dart';
import 'package:recycle_mate/pages/home_page.dart';
import 'package:recycle_mate/pages/login_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycle Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: BottomNav(),
      // home: AdminReedem(),


    );
  }
}
