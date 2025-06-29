import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';

class UploadItem extends StatefulWidget {
  String category, id;

  UploadItem({required this.category, required this.id});

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  TextEditingController addresscontroller = new TextEditingController();
  TextEditingController quantitycontroller = new TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? id, name;

  getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  @override
  void initState() {
    getthesharedpref();
    super.initState();
  }

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(image!.path);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
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
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFececf8),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 5),
                  Text("Upload Item", style: AppWidget.headlineTextStyle(25.0)),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  // color: Color(0xFFececf8),
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30.0),
                      selectedImage != null
                          ? Center(
                            child: Container(
                                height: 160,
                                width: 160,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          )
                          : GestureDetector(
                              onTap: () {
                                getImage();
                              },
                              child: Center(
                                child: Container(
                                  height: 160,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.black45,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ),
                  
                      SizedBox(height: 30.0),
                  
                      // Show selected category
                      Center(
                        child: Text(
                          "Selected Category: ${widget.category}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  
                      SizedBox(height: 20.0),
                  
                      //Address
                      SizedBox(height: 30.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        child: Text(
                          "Enter your Address you want the time to be picked.",
                          style: AppWidget.normalTextStyle(18.0),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Container(
                        margin: EdgeInsets.only(left: 20.0, right: 20.0),
                        child: Material(
                          elevation: 3.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: addresscontroller,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.green,
                                ),
                                hintText: "Enter Address",
                                // hintStyle: AppWidget.normalTextStyle(16.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                  
                      //Quantity
                      SizedBox(height: 40.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        child: Text(
                          "Enter the Quantity of the items to be picked.",
                          style: AppWidget.normalTextStyle(18.0),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Container(
                        margin: EdgeInsets.only(left: 20.0, right: 20.0),
                        child: Material(
                          elevation: 3.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: quantitycontroller,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.inventory,
                                  color: Colors.green,
                                ),
                                hintText: "Enter Quantity",
                                // hintStyle: AppWidget.normalTextStyle(16.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      //Quantity code finished
                      SizedBox(height: 40.0),
                      GestureDetector(
                        onTap: () async {
                          if (addresscontroller.text != "" && quantitycontroller.text != "") {
                            String itemId = randomAlphaNumeric(10);
                  
                            // for the firebase storage
                          // if (selectedImage != null &&
                          //     addresscontroller.text.isNotEmpty &&
                          //     quantitycontroller.text.isNotEmpty) {
                          //   String itemId = randomAlphaNumeric(10);
                          //   Reference firebaseStorageRef = FirebaseStorage
                          //       .instance
                          //       .ref()
                          //       .child("blogImage")
                          //       .child(itemId);
                          //   final UploadTask task = firebaseStorageRef.putFile(
                          //     selectedImage!,
                          //   );
                          //   var downloadUrl = await (await task).ref
                          //       .getDownloadURL();
                  
                            Map<String, dynamic> addItem = {
                              // "Image": downloadUrl,
                              "Category": widget.category,
                              "Image": "",
                              "Address": addresscontroller.text,
                              "Quantity": quantitycontroller.text,
                              "UserId": id,
                              "Name": name,
                              "Status": "Pending",
                            };
                            await DatabaseMethods().addUserUploadItem(
                              addItem,
                              id!,
                              itemId,
                            );
                            await DatabaseMethods().addAdminItem(addItem, itemId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                  "Item has been uploaded Successfully!",
                                  style: AppWidget.whiteTextStyle(22.0),
                                ),
                              ),
                            );
                            setState(() {
                              addresscontroller.text = "";
                              quantitycontroller.text = "";
                              selectedImage= null;
                            });
                            Future.delayed(Duration(milliseconds: 800), () {
                              Navigator.pop(context);
                            });
                          }
                        },
                        child: Center(
                          child: Material(
                            elevation: 2.0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 50.0,
                              width: MediaQuery.of(context).size.width / 1.5,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  "Upload",
                                  style: AppWidget.whiteTextStyle(26.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
