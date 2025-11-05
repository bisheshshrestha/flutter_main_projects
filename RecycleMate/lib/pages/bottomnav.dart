import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/pages/home_page.dart';
import 'package:recycle_mate/pages/points.dart';
import 'package:recycle_mate/pages/profile.dart';


class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  late List<Widget> pages;

  late HomePage homePage;
  late Points points;
  late Profile profilePage;

  int currentTabIndex = 0;


  @override
  void initState() {
    homePage = HomePage();
    points = Points();
    profilePage = Profile();
    pages = [homePage, points, profilePage];
    super.initState();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
          height: 40,
          backgroundColor: Colors.white,
          color: Colors.black,
          animationDuration: Duration(milliseconds: 500),
          onTap: (int index){
            setState(() {
              currentTabIndex = index;
            });
          },
          items: [
            Icon(Icons.home, size: 34, color: Colors.white,),
            Icon(Icons.point_of_sale, size: 34, color: Colors.white,),
            Icon(Icons.person, size: 34, color: Colors.white,),
          ]),
      body: pages[currentTabIndex],
    );
  }
}
