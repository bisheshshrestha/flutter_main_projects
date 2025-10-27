// File: lib/main_user.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/pages/bottomnav.dart';
import 'package:recycle_mate/pages/login_page.dart';
import 'package:recycle_mate/services/shared_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecycleMate User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: const UserRootPage(),
    );
  }
}

class UserRootPage extends StatefulWidget {
  const UserRootPage({Key? key}) : super(key: key);

  @override
  State<UserRootPage> createState() => _UserRootPageState();
}

class _UserRootPageState extends State<UserRootPage> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
  }

  Future<void> _checkUserLogin() async {
    final id = await SharedPreferenceHelper().getUserId();
    final role = await SharedPreferenceHelper().getUserRole();
    setState(() {
      isLoggedIn = id != null && id.isNotEmpty && (role == 'user' || role == null);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    return isLoggedIn ? const BottomNav() : const LoginPage();
  }
}
