import 'package:flutter/material.dart';
import 'package:recycle_mate/pages/upload_item.dart';
import 'package:recycle_mate/services/widget_support.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40, left: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 5.0,),
                  Image.asset("assets/images/wave.png",height:30,width: 30, fit: BoxFit.cover,),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text("Hello, ", style: AppWidget.headlineTextStyle(26.0)),
                  ),
                  Text("Bishesh", style: AppWidget.greenTextStyle(25.0)),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        "assets/images/boy.jpg",
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30,),
              Center(child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Image.asset("assets/images/home.png"),
              )),
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text("Categories",style: AppWidget.headlineTextStyle(22.0),),
              ),
              SizedBox(height: 20,),
              Container(
                padding: EdgeInsets.only(left: 20.0),
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    buildCategoryItem("assets/images/plastic.png", "Plastic"),
                    SizedBox(width: 20.0,),
                    buildCategoryItem("assets/images/paper.png", "Paper"),
                    SizedBox(width: 20.0,),
                    buildCategoryItem("assets/images/battery.png", "Battery"),
                    SizedBox(width: 20.0,),
                    buildCategoryItem("assets/images/glass.png", "Glass"),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text("Pending Request",style: AppWidget.headlineTextStyle(22.0),),
              ),
              SizedBox(height: 20,),
              Container(
                margin: EdgeInsets.only(left: 20.0 ,right: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black45,width: 2.0),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                        color: Colors.green,
                          size: 30.0,
                        ),
                        SizedBox(width: 10.0,),
                        Text("Newroad Kathmandu", style: AppWidget.normalTextStyle(20.0),)

                      ],
                    ),
                    Divider(),
                    Image.asset("assets/images/chips.png",height: 120, width: 120, fit: BoxFit.cover,),
                    SizedBox(width: 10.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers,
                          color: Colors.green,
                          size: 30.0,
                        ),
                        SizedBox(width: 10.0,),
                        Text(
                          "3",
                          style: AppWidget.normalTextStyle(24.0),
                        )
                      ],
                    ),
                    SizedBox(height: 10.0,),
                  ],
                ),
              ),
              SizedBox(height: 30,),
            ],
          ),
        ),
      ),
    );
  }
  Widget buildCategoryItem(String imagePath, String label) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> UploadItem(category: "Plastic", id: id)));
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFececf8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black45, width: 2.0),
            ),
            child: Image.asset(imagePath, height: 70, width: 70, fit: BoxFit.cover),
          ),
          SizedBox(height: 5.0),
          Text(label, style: AppWidget.normalTextStyle(20.0)),
        ],
      ),
    );
  }
}
