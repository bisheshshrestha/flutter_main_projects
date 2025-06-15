
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recycle_mate/pages/home_page.dart';
import 'package:recycle_mate/services/database.dart';

class AuthMethods{
  signInwithGoogle(BuildContext context) async{
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken
    );

    UserCredential result = await firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;
    if(userDetails != null){
      //save the user info to our server
      Map<String,dynamic> userInfoMap = {
        "email" : userDetails.email,
        "name" : userDetails.displayName,
        "image": userDetails.photoURL,
        "Id": userDetails.uid,
      };

      await DatabaseMethods().addUserInfo(userInfoMap, userDetails.uid);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    }

  }
}