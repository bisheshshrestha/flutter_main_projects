
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recycle_mate/pages/bottomnav.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';

class AuthMethods{
  signInwithGoogle(BuildContext context) async{
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await googleSignIn.signOut();


    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount == null) {
      return;
    }

    final GoogleSignInAuthentication? googleSignInAuthentication =
    await googleSignInAccount.authentication;


    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken
    );

    UserCredential result = await firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;
    await SharedPreferenceHelper().saveUserEmail(userDetails!.email!);
    await SharedPreferenceHelper().saveUserId(userDetails.uid);
    await SharedPreferenceHelper().saveUserImage(userDetails.photoURL!);
    await SharedPreferenceHelper().saveUserName(userDetails.displayName!);

    if(result != null){
      //save the user info to our server
      Map<String,dynamic> userInfoMap = {
        "email" : userDetails!.email,
        "name" : userDetails.displayName,
        "image": userDetails.photoURL,
        "Id": userDetails.uid,
        "points": "0"
      };

      await DatabaseMethods().addUserInfo(userInfoMap, userDetails.uid);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
    }

  }
  Future SignOut() async{
    await FirebaseAuth.instance.signOut();
  }
  Future deleteUser() async{
    User? user = await FirebaseAuth.instance.currentUser;
    user?.delete();
  }
}