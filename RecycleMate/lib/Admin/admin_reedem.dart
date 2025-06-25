import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/widget_support.dart';

class AdminReedem extends StatefulWidget {
  const AdminReedem({super.key});

  @override
  State<AdminReedem> createState() => _AdminReedemState();
}

class _AdminReedemState extends State<AdminReedem> {

  Stream? reedemStream;

  getontheload() async{
    reedemStream = await DatabaseMethods().getAdminReedemApproval();
    setState(() {

    });
  }
  @override
  void initState() {
    getontheload();
    super.initState();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFececf8),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 7),
                  Expanded(
                    child: Text(
                      "Reedem Approval",
                      style: AppWidget.headlineTextStyle(25.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // List of dynamic approval cards
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 251, 251, 251),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.0),
                    Container(
                        height: MediaQuery.of(context).size.height / 1.5,
                        child: allApprovals()),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget allApprovals() {
    return StreamBuilder(
      stream: reedemStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            return Container(
              padding: EdgeInsets.all(10.0),
              margin: EdgeInsets.only(left: 20.0, right: 20.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(color: Colors.black,
                      borderRadius: BorderRadius.circular(10.0),

                    ),

                    child: Text(
                      ds["Date"],
                      textAlign: TextAlign.center,
                      style: AppWidget.whiteTextStyle(22.0),
                    ),
                  ),
                  SizedBox(width: 20.0,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,color: Colors.green,size: 25.0,),
                          SizedBox(width: 10.0,),
                          Text(ds["Name"],style: AppWidget.normalTextStyle(18.0),)
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.point_of_sale,color: Colors.green,size: 25.0,),
                          SizedBox(width: 10.0,),
                          Text("Points Reedem: "+ds["Points"],style: AppWidget.normalTextStyle(18.0),)
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.monetization_on,color: Colors.green,size: 25.0,),
                          SizedBox(width: 10.0,),
                          Text("Esewa ID: "+ ds["Esewa ID"],style: AppWidget.normalTextStyle(18.0),)
                        ],
                      ),
                      SizedBox(height: 5.0,),
                      GestureDetector(
                        onTap: () async {
                          await DatabaseMethods().updateAdminReedemRequests(ds.id);
                          await DatabaseMethods().updateUserReedemRequests(ds["User ID"], ds.id);

                        },
                        child: Container(
                          height: 40,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Center(child: Text("Approved",style: AppWidget.whiteTextStyle(20.0),)),
                        ),
                      )
                    ],

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
