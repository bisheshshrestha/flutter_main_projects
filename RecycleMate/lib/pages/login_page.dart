// File: lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_mate/services/auth.dart';
import 'package:recycle_mate/services/widget_support.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/pages/bottomnav.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool _obscure = true;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Perform email auth and get UserCredential
      UserCredential credential;
      if (isLogin) {
        credential = await AuthMethods().signInWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        credential = await AuthMethods().signUpWithEmail(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
        );
      }

      // Extract UID
      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Failed to get user ID');

      // Save to SharedPreferences
      await SharedPreferenceHelper().saveUserId(uid);
      await SharedPreferenceHelper().saveUserRole('user');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }
    try {
      await AuthMethods().sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Password reset email sent")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Image.asset(
                "assets/images/login.png",
                height: 220,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Image.asset(
                "assets/images/recycle1.png",
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Text(
                "Reduce. Reuse. Recycle.",
                style: AppWidget.headlineTextStyle(22.0),
              ),
              Text("Repeat!", style: AppWidget.greenTextStyle(30.0)),
              const SizedBox(height: 16),
              Text(
                "Every item you recycle makes a difference!",
                textAlign: TextAlign.center,
                style: AppWidget.normalTextStyle(16.0),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Login"),
                    selected: isLogin,
                    onSelected: (v) => setState(() => isLogin = true),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("Register"),
                    selected: !isLogin,
                    onSelected: (v) => setState(() => isLogin = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin)
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) {
                          if (isLogin) return null;
                          if (v == null || v.trim().length < 2) {
                            return "Enter a valid name";
                          }
                          return null;
                        },
                      ),
                    if (!isLogin) const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Email is required";
                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                        return ok ? null : "Enter a valid email";
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Password is required";
                        if (v.length < 6) return "At least 6 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text("Forgot password?"),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleEmailAuth,
                        child: Text(
                          isLogin ? "Login" : "Create Account",
                          style: AppWidget.whiteTextStyle(20.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text("or", style: AppWidget.normalTextStyle(16.0)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final uid = await AuthMethods().signInwithGoogle(context);
                  if (uid != null) {
                    await SharedPreferenceHelper().saveUserId(uid);
                    await SharedPreferenceHelper().saveUserRole('user');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BottomNav()),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      height: 56,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Image.asset("assets/images/google.png",
                                height: 36, width: 36, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12.0),
                          Text("Sign in with Google",
                              style: AppWidget.whiteTextStyle(20.0)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
