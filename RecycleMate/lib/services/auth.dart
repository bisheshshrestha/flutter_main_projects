import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recycle_mate/pages/bottomnav.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Existing Google sign-in (unchanged)
  signInwithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await googleSignIn.signOut();
    final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
    if (googleSignInAccount == null) return;

    final GoogleSignInAuthentication? googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken,
    );

    UserCredential result = await firebaseAuth.signInWithCredential(credential);
    User? userDetails = result.user;

    await SharedPreferenceHelper().saveUserEmail(userDetails!.email!);
    await SharedPreferenceHelper().saveUserId(userDetails.uid);
    await SharedPreferenceHelper().saveUserImage(userDetails.photoURL ?? "");
    await SharedPreferenceHelper().saveUserName(userDetails.displayName ?? "");

    if (result.user != null) {
      final userInfoMap = {
        "email": userDetails.email,
        "name": userDetails.displayName ?? "",
        "image": userDetails.photoURL ?? "",
        "Id": userDetails.uid,
        "points": "0",
      };
      await DatabaseMethods().addUserInfo(userInfoMap, userDetails.uid);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNav()));
    }
  }

  // New: Sign up with email + password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optionally update profile displayName
    if (name != null && name.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(name.trim());
    }
    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : email.split('@').first;

    // Create Firestore user doc (points start at 0)
    final userInfoMap = {
      "email": email,
      "name": displayName,
      "image": "", // No image yet
      "Id": cred.user!.uid,
      "points": "0",
    };
    await DatabaseMethods().addUserInfo(userInfoMap, cred.user!.uid);

    // Save to SharedPreferences
    await SharedPreferenceHelper().saveUserEmail(email);
    await SharedPreferenceHelper().saveUserId(cred.user!.uid);
    await SharedPreferenceHelper().saveUserImage("");
    await SharedPreferenceHelper().saveUserName(displayName);

    return cred;
  }

  // New: Sign in with email + password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Load basic profile into SharedPreferences
    await SharedPreferenceHelper().saveUserEmail(cred.user!.email ?? email);
    await SharedPreferenceHelper().saveUserId(cred.user!.uid);
    await SharedPreferenceHelper().saveUserImage(cred.user!.photoURL ?? "");
    await SharedPreferenceHelper().saveUserName(cred.user!.displayName ?? email.split('@').first);

    return cred;
  }

  // New: Password reset
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future SignOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future deleteUser() async {
    User? user = await FirebaseAuth.instance.currentUser;
    user?.delete();
  }
}