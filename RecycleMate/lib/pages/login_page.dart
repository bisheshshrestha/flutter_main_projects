import 'package:flutter/material.dart';
import 'package:recycle_mate/services/widget_support.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Center(
              child: Image.asset(
                "assets/images/login.png",
                height: 300,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            Image.asset(
              "assets/images/recycle1.png",
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              "Reduce. Reuse. Recycle.",
              style: AppWidget.headlineTextStyle(25.0),
            ),
            Text("Repeat!", style: AppWidget.greenTextStyle(35.0)),
            SizedBox(height: 30),
            Text(
              "Every item you recycle\n makes a difference!",
              textAlign: TextAlign.center,
              style: AppWidget.normalTextStyle(20.0),
            ),
            Text("Get Started", style: AppWidget.greenTextStyle(24.0)),
            SizedBox(height: 50,),
            Container(
              margin:EdgeInsets.only(left: 20.0, right: 20.0),
              child: Material(
                elevation: 4.0,
                  borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.only(left: 20.0),
                  decoration: BoxDecoration(color: Colors.green,
                  borderRadius: BorderRadius.circular(30)),
                  child: Row(children: [
                    Container(
                        padding: EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50)
                        ),
                        child: Image.asset("assets/images/google.png",height: 50,width: 50,fit: BoxFit.cover,)),
                    SizedBox(height: 20.0,),
                    Text("Sign in with Google",style: AppWidget.whiteTextStyle(25.0),),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
