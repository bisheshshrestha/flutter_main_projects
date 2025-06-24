import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';

class Points extends StatefulWidget {
  const Points({super.key});

  @override
  State<Points> createState() => _PointsState();
}

class _PointsState extends State<Points> {

  String? id, mypoints,name;
  Stream? pointStream;

  getthesharedprefs() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    setState(() {

    });
  }
  ontheload() async{
    await getthesharedprefs();
    mypoints = await getUserPoints(id!);
    pointStream = await DatabaseMethods().getUserTransactions(id!);

    setState(() {

    });
  }
  @override
  void initState() {
    ontheload();
    super.initState();
  }

  TextEditingController pointscontroller = TextEditingController();
  TextEditingController esewacontroller = TextEditingController();

  Future<String> getUserPoints(String docId) async{
    try{
      //Reference to the 'users' collection and specific document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if(docSnapshot.exists){
        //Get the 'userpoints' field
        var data = docSnapshot.data() as Map<String, dynamic>;
        return data['points'].toString();
      }else{
        print('No such document!');
        return 'No document';
      }
    }catch(e){
      print("Error fetching user points! $e");
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mypoints == null ? const Center(child: CircularProgressIndicator()) : Container(
        margin: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Center(
              child: Text(
                "Points Page",
                style: AppWidget.headlineTextStyle(28.0),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 233, 233, 249),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(children: [
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Image.asset(
                              "assets/images/coin.png",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 50.0),
                            Column(
                              children: [
                                Text("Points Earned",
                                    style: AppWidget.normalTextStyle(20.0)),
                                const SizedBox(height: 10),
                                Text(mypoints.toString(),
                                    style: AppWidget.greenTextStyle(28.0)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      openBox();
                    },
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        height: 50.0,
                        width: MediaQuery.of(context).size.width / 1.5,
                        child: Center(
                          child: Text(
                            "Redeem Points",
                            style: AppWidget.whiteTextStyle(20.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0,),
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10.0,),
                          Text("Last Transactions",style: AppWidget.normalTextStyle(20.0)),
                          SizedBox(height: 20.0,),
                          Container(
                              height: MediaQuery.of(context).size.height / 2,
                              child: allApprovals()),
                        ]
                      ),
                    ),
                  )
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future openBox() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.cancel),
                ),
                const SizedBox(width: 30.0),
                Text("Redeem Points",
                    style: AppWidget.greenTextStyle(20.0)),
              ],
            ),
            const SizedBox(height: 20.0),
            Text("Add Points", style: AppWidget.normalTextStyle(20.0)),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: pointscontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Points",
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text("Add Esewa ID", style: AppWidget.normalTextStyle(20.0)),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: esewacontroller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Esewa ID",
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () async{
                if(pointscontroller.text != "" && esewacontroller.text != "" && int.parse(mypoints!) > int.parse(pointscontroller.text)  ){
                  DateTime now  =DateTime.now();
                  String formattedDate = DateFormat('d\nMM').format(now);
                  int updatedPoints = int.parse(mypoints!) - int.parse(pointscontroller.text);
                  await DatabaseMethods().updateUserPoints(id!, updatedPoints.toString());

                  Map<String,dynamic> userRedeemMap = {
                    "Name":name,
                    "Points":pointscontroller.text,
                    "Esewa ID":esewacontroller.text,
                    "Status":"Pending",
                    "Date":formattedDate,
                  };
                  String reedemId = randomAlphaNumeric(10);
                  await DatabaseMethods().addUserRedeemPoints(userRedeemMap, id!, reedemId);
                  await DatabaseMethods().addAdminRedeemRequests(userRedeemMap, reedemId);
                  mypoints = await getUserPoints(id!);


                  setState(() {
                  });
                  Navigator.pop(context);
                }
              },
              child: Center(
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: Text(
                      "Redeem",
                      style: AppWidget.whiteTextStyle(20.0),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    ),
  );

  Widget allApprovals() {
    return StreamBuilder(
      stream: pointStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            return  Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(left: 16.0,right: 16.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 233, 233, 249),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black ,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(ds["Date"],textAlign:TextAlign.center,style: AppWidget.whiteTextStyle(18.0),),
                  ),
                  SizedBox(width: 20.0,),
                  Column(
                    children: [
                      Text("Redeem Points",style: AppWidget.normalTextStyle(18.0),),
                      Text(ds["Points"],style: AppWidget.greenTextStyle(24.0),),
                    ],
                  ),
                  SizedBox(width: 25.0,),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(48, 241, 77, 66),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(ds["Status"],style: TextStyle(color: Colors.red,fontSize: 18.0,fontWeight: FontWeight.bold),),
                  )

                ],
              ),
            );
          },
        );
      },
    );
  }
}
