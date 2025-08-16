import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';
import 'package:recycle_mate/services/apis.dart'; // ImageKitApi

class UploadItem extends StatefulWidget {
  final String category;
  final String id;

  UploadItem({required this.category, required this.id});

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  final TextEditingController addresscontroller = TextEditingController();
  final TextEditingController quantitycontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  String? id, name;

  // Dynamic quantity + points
  late final bool _isPlastic;
  late final String _unitLabel; // 'piece' or 'kg'
  late final double _rate; // points per unit
  double _qty = 0;
  int _totalPoints = 0;

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
    // Set unit + rate by category
    final cat = widget.category.toLowerCase();
    _isPlastic = cat.contains('plastic'); // covers "Plastic Bottle"
    _unitLabel = _isPlastic ? 'piece' : 'kg';
    _rate = _isPlastic
        ? 2 // plastic: 2 points per piece
        : (cat.contains('paper')
        ? 10 // paper: 10 points per kg
        : 20 // glass: 20 points per kg
    );

    _loadSharedPref();
    _fetchAndSortLocationsByDistance();

    // Listen for quantity changes to recalc points
    quantitycontroller.addListener(_onQtyChanged);
  }

  @override
  void dispose() {
    quantitycontroller.removeListener(_onQtyChanged);
    quantitycontroller.dispose();
    addresscontroller.dispose();
    super.dispose();
  }

  void _onQtyChanged() {
    final raw = quantitycontroller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _qty = 0;
        _totalPoints = 0;
      });
      return;
    }
    // Plastic piece -> int; kg -> double
    final parsed = _isPlastic ? double.tryParse(raw) : double.tryParse(raw);
    final q = (parsed ?? 0);
    // For plastic, only whole pieces count
    final effectiveQty = _isPlastic ? q.floor().toDouble() : q;
    setState(() {
      _qty = effectiveQty;
      _totalPoints = (_rate * effectiveQty).round();
    });
  }

  Future<void> _loadSharedPref() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {});
    }
  }

  double _distanceKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _fetchAndSortLocationsByDistance() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    final withDistance = pickupLocations.map((loc) {
      final dist = _distanceKm(pos.latitude, pos.longitude, loc['lat'], loc['lng']);
      return {"name": loc['name'], "lat": loc['lat'], "lng": loc['lng'], "distance": dist};
    }).toList();

    withDistance.sort((a, b) => a["distance"].compareTo(b["distance"]));

    setState(() {
      sortedLocations = withDistance;
      selectedLocation = withDistance.isNotEmpty ? withDistance.first["name"] : null;
      if (selectedLocation != null) addresscontroller.text = selectedLocation!;
    });
  }

  Future<void> _submit() async {
    if (id == null) return;
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }
    if (addresscontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a pickup location")));
      return;
    }
    if (_qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid ${_isPlastic ? 'number of pieces' : 'weight in kg'}")),
      );
      return;
    }

    final itemId = randomAlphaNumeric(10);

    // Upload image to ImageKit (your apis.dart)
    final imageUrl = await ImageKitApi.uploadImage(selectedImage!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed. Try again.")),
      );
      return;
    }

    final addItem = {
      "Category": widget.category,
      "Image": imageUrl,
      "Address": addresscontroller.text.trim(),
      "Quantity": _isPlastic ? _qty.toInt() : _qty, // store int for plastic, double for kg
      "QuantityUnit": _unitLabel, // 'piece' or 'kg'
      "UserId": id,
      "Name": name,
      "Status": "Pending",
      "Points": _totalPoints,
      "CreatedAt": FieldValue.serverTimestamp()
      // optional, used for display/admin reference
      // If you also want ordered history, add createdAt on client (or on admin when approved)
      // "createdAt": FieldValue.serverTimestamp(), // requires cloud_firestore import
    };

    await DatabaseMethods().addUserUploadItem(addItem, id!, itemId);
    await DatabaseMethods().addAdminItem(addItem, itemId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item uploaded successfully!")));
    setState(() {
      addresscontroller.clear();
      quantitycontroller.clear();
      selectedImage = null;
      _qty = 0;
      _totalPoints = 0;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unitHint = _isPlastic ? "Enter number of pieces" : "Enter weight in kg (e.g. 1.5)";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new)),
                  const SizedBox(width: 16),
                  Text("Upload Item", style: AppWidget.headlineTextStyle(25.0)),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image picker
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(selectedImage!, height: 160, width: 160, fit: BoxFit.cover),
                            )
                                : Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black45, width: 2.0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.camera_alt_outlined, size: 30.0),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Selected Category: ${widget.category}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Drop off location
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Select a drop off location near you:", style: AppWidget.normalTextStyle(18.0)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26, width: 1.5),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedLocation,
                        underline: const SizedBox(),
                        items: sortedLocations.map((loc) {
                          return DropdownMenuItem<String>(
                            value: loc["name"],
                            child: Text("${loc["name"]} - ${loc["distance"].toStringAsFixed(2)} km"),
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

                    const SizedBox(height: 30),

                    // Quantity input with dynamic unit
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Enter the quantity (${_unitLabel}):",
                        style: AppWidget.normalTextStyle(18.0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantitycontroller,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !_isPlastic, // allow decimal for kg
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.inventory, color: Colors.green),
                        hintText: unitHint,
                        border: const OutlineInputBorder(),
                        suffixText: _unitLabel,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Notes and dynamic points
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Points Guide", style: AppWidget.headlineTextStyle(18.0)),
                          const SizedBox(height: 8),
                          const Text("• Plastic bottle: 1 piece = 2 points"),
                          const Text("• Paper: 1 kg = 10 points"),
                          const Text("• Glass: 1 kg = 20 points"),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text("You will earn: ", style: AppWidget.normalTextStyle(16.0)),
                              Text("$_totalPoints points",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          Text(
                            "(Final points are awarded after admin approval)",
                            style: AppWidget.normalTextStyle(12.0).copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width / 1.5,
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                        child: Center(child: Text("Upload", style: AppWidget.whiteTextStyle(22.0))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}