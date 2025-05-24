import 'package:flutter/material.dart';
import 'package:recycle_mate/services/widget_support.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 50,),
            Image.asset("assets/images/onboard.png"),
            SizedBox(height: 50.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Recycle your waste products!",
                style: AppWidget.headlineTextStyle(32.0),
              ),
            ),
            SizedBox(height: 30,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text("Easily collect household waste and generate less waste",style: AppWidget.normalTextStyle(20.0),),
            ),
            SizedBox(height:50,),
            Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                height: 70,
                width: MediaQuery.of(context).size.width / 1.5,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(child: Text("Get Started",style: AppWidget.whiteTextStyle(24.0),)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
