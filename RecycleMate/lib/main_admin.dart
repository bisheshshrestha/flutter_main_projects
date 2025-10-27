// File: lib/main_admin.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/Admin/admin_login.dart';
import 'package:recycle_mate/Admin/admin_home.dart';
import 'package:recycle_mate/services/shared_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecycleMate Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: const AdminRootPage(),
    );
  }
}

class AdminRootPage extends StatefulWidget {
  const AdminRootPage({Key? key}) : super(key: key);

  @override
  State<AdminRootPage> createState() => _AdminRootPageState();
}

class _AdminRootPageState extends State<AdminRootPage> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAdminLogin();
  }

  Future<void> _checkAdminLogin() async {
    final id = await SharedPreferenceHelper().getUserId();
    final role = await SharedPreferenceHelper().getUserRole();
    setState(() {
      isLoggedIn = id != null && id.isNotEmpty && role == 'admin';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return isLoggedIn ? const AdminHome() : const AdminLogin();
  }
}
