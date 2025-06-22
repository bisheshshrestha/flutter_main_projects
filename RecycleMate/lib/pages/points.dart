import 'package:flutter/material.dart';
import 'package:recycle_mate/services/widget_support.dart';

class Points extends StatefulWidget {
  const Points({super.key});

  @override
  State<Points> createState() => _PointsState();
}

class _PointsState extends State<Points> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 40),
        child:
        Column(
          children: [
            Center(child: Text("Points Page",style: AppWidget.headlineTextStyle(28.0),)),
            SizedBox(height: 20,),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 233, 233, 249),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20,),
                  Text("Your Points",style: AppWidget.headlineTextStyle(22.0),),
                  SizedBox(height: 20,),
                  Text("0",style: AppWidget.headlineTextStyle(28.0),),
                  SizedBox(height: 20,),
                  Text("Your Rewards",style: AppWidget.headlineTextStyle(22.0),),
                  SizedBox(height: 20,),
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
}
