import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';
import 'package:recycle_mate/services/apis.dart';

class UploadItem extends StatefulWidget {
  final String category;
  final String id;

  UploadItem({required this.category, required this.id});

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  TextEditingController addresscontroller = TextEditingController();
  TextEditingController quantitycontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? id, name;

  List<Map<String, dynamic>> pickupLocations = [
    {"name": "Pulchowk", "lat": 27.6795, "lng": 85.3170},
    {"name": "Baneshwor", "lat": 27.6946, "lng": 85.3420},
    {"name": "Kalanki", "lat": 27.6941, "lng": 85.2771},
    {"name": "Thamel", "lat": 27.7167, "lng": 85.3123},
  ];

  String? selectedLocation;
  List<Map<String, dynamic>> sortedLocations = [];

  @override
  void initState() {
    super.initState();
    getthesharedpref();
    fetchAndSortLocationsByDistance();
  }

  Future<void> getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {});
    }
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> fetchAndSortLocationsByDistance() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    List<Map<String, dynamic>> withDistance = pickupLocations.map((loc) {
      double dist =
      calculateDistance(pos.latitude, pos.longitude, loc['lat'], loc['lng']);
      return {
        "name": loc['name'],
        "lat": loc['lat'],
        "lng": loc['lng'],
        "distance": dist,
      };
    }).toList();

    withDistance.sort((a, b) => a["distance"].compareTo(b["distance"]));

    setState(() {
      sortedLocations = withDistance;
      selectedLocation = sortedLocations.first["name"];
      addresscontroller.text = selectedLocation!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new),
                  ),
                  SizedBox(width: 16),
                  Text("Upload Item", style: AppWidget.headlineTextStyle(25.0)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: getImage,
                              child: selectedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  selectedImage!,
                                  height: 160,
                                  width: 160,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Container(
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black45, width: 2.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.camera_alt_outlined,
                                    size: 30.0),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Selected Category: ${widget.category}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select a pickup location near you:",
                          style: AppWidget.normalTextStyle(18.0),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: Colors.black26, width: 1.5),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedLocation,
                          underline: SizedBox(),
                          items: sortedLocations.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc["name"],
                              child: Text(
                                  "${loc["name"]} - ${loc["distance"].toStringAsFixed(2)} km"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedLocation = val;
                              addresscontroller.text = val ?? "";
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Enter the Quantity of the items to be picked:",
                          style: AppWidget.normalTextStyle(18.0),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: quantitycontroller,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.inventory, color: Colors.green),
                          hintText: "Enter Quantity",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: () async {
                          if (addresscontroller.text != "" &&
                              quantitycontroller.text != "") {
                            String itemId = randomAlphaNumeric(10);

                            // Upload image to ImageKit
                            String? imageUrl = await ImageKitApi.uploadImage(selectedImage!);

                            if (imageUrl == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Image upload failed. Try again.")),
                              );
                              return;
                            }
                            Map<String, dynamic> addItem = {
                              "Category": widget.category,
                              "Image": imageUrl,
                              "Address": addresscontroller.text,
                              "Quantity": quantitycontroller.text,
                              "UserId": id,
                              "Name": name,
                              "Status": "Pending",
                            };
                            await DatabaseMethods()
                                .addUserUploadItem(addItem, id!, itemId);
                            await DatabaseMethods().addAdminItem(addItem, itemId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Item uploaded successfully!")),
                            );
                            setState(() {
                              addresscontroller.clear();
                              quantitycontroller.clear();
                              selectedImage = null;
                            });
                            Future.delayed(
                                Duration(milliseconds: 800),
                                    () => Navigator.pop(context));
                          }
                        },
                        child: Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width / 1.5,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text("Upload",
                                style: AppWidget.whiteTextStyle(22.0)),
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

