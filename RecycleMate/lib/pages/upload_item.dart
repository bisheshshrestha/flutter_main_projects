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
import 'package:recycle_mate/services/apis.dart';
import 'package:recycle_mate/services/ml_classification.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UploadItem extends StatefulWidget {
  final String? category;
  final String id;

  UploadItem({this.category, required this.id});

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  final TextEditingController addresscontroller = TextEditingController();
  final TextEditingController quantitycontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  String? id, name;
  bool _loading = false;
  ClassificationResult? _mlResult;

  Position? _userPosition;
  LatLng? _selectedLocationPoint; // Store selected location
  MapController? mapController;

  String? _selectedCategory;
  final Map<String, double> _pointsPerKg = {
    'Plastic': 5.0,
    'Paper': 10.0,
    'Glass': 20.0,
    'Cardboard': 8.0,
    'Metal': 15.0,
  };

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
    _selectedCategory = widget.category;
    _loadSharedPref();
    _fetchAndSortLocationsByDistance();
    _initML();
    quantitycontroller.addListener(_onQtyChanged);
  }

  @override
  void dispose() {
    quantitycontroller.removeListener(_onQtyChanged);
    quantitycontroller.dispose();
    addresscontroller.dispose();
    MLClassificationService.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initML() async {
    try {
      await MLClassificationService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize ML: $e')),
        );
      }
    }
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
    final parsed = double.tryParse(raw) ?? 0;
    final rate = _pointsPerKg[_selectedCategory] ?? 0.0;
    setState(() {
      _qty = parsed;
      _totalPoints = (rate * parsed).round();
    });
  }

  Future<void> _loadSharedPref() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {
        _mlResult = null;
      });
      await _runMLClassification();
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runMLClassification() async {
    if (selectedImage == null) return;

    try {
      setState(() => _loading = true);
      final result = await MLClassificationService.classifyImage(selectedImage!);

      setState(() {
        _mlResult = result;
        if (result.success && result.category != null) {
          _selectedCategory = result.category;
          _onQtyChanged();
        }
      });

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Classification failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
    setState(() => _userPosition = pos);

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

  // Handle map tap to select location
  void _onMapTap(LatLng point) {
    // Find closest pickup location to tap point
    double closestDistance = double.infinity;
    Map<String, dynamic>? closestLocation;

    for (var loc in sortedLocations) {
      double dist = _distanceKm(point.latitude, point.longitude, loc['lat'], loc['lng']);
      if (dist < closestDistance) {
        closestDistance = dist;
        closestLocation = loc;
      }
    }

    // If tapped near a location (within 1 km), select it
    if (closestDistance < 1.0 && closestLocation != null) {
      setState(() {
        selectedLocation = closestLocation!['name'];
        addresscontroller.text = selectedLocation!;
        _selectedLocationPoint = LatLng(closestLocation['lat'], closestLocation['lng']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${closestLocation['name']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap near a pickup location')),
      );
    }
  }

  Future<void> _submit() async {
    if (id == null) return;
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }
    if (addresscontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a pickup location")));
      return;
    }
    if (_qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid weight in kg")),
      );
      return;
    }

    setState(() => _loading = true);

    final itemId = randomAlphaNumeric(10);

    final imageUrl = await ImageKitApi.uploadImage(selectedImage!);
    if (imageUrl == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed. Try again.")),
      );
      return;
    }

    final addItem = {
      "Category": _selectedCategory,
      "Image": imageUrl,
      "Address": addresscontroller.text.trim(),
      "Quantity": _qty,
      "QuantityUnit": "kg",
      "UserId": id,
      "Name": name,
      "Status": "Pending",
      "Points": _totalPoints,
      "CreatedAt": FieldValue.serverTimestamp(),
      if (_mlResult != null) "MLData": {
        "predictedLabel": _mlResult!.predictedLabel,
        "confidence": _mlResult!.confidence,
        "success": _mlResult!.success,
      },
    };

    try {
      await DatabaseMethods().addUserUploadItem(addItem, id!, itemId);
      await DatabaseMethods().addAdminItem(addItem, itemId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item uploaded successfully!")));
      setState(() {
        addresscontroller.clear();
        quantitycontroller.clear();
        selectedImage = null;
        _selectedCategory = widget.category;
        _mlResult = null;
        _qty = 0;
        _totalPoints = 0;
        _selectedLocationPoint = null;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            onTap: _showImageSourceDialog,
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
                          const SizedBox(height: 12),
                          if (_loading)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Detecting category...'),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ML Result Card
                    if (_mlResult != null) _buildMLResultCard(),

                    const SizedBox(height: 20),

                    // Category Selection
                    _buildCategorySelection(),

                    const SizedBox(height: 30),

                    // MAP - WITH POLYLINE AND TAP
                    Text("Click on a location on the map to select:", style: AppWidget.normalTextStyle(16.0)),
                    const SizedBox(height: 10),
                    _buildMapWidget(),

                    const SizedBox(height: 30),

                    // Drop off location
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Selected location:", style: AppWidget.normalTextStyle(18.0)),
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
                            // Update selected location point
                            final loc = sortedLocations.firstWhere((l) => l['name'] == val);
                            _selectedLocationPoint = LatLng(loc['lat'], loc['lng']);
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Quantity input
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Enter the quantity (kg):",
                        style: AppWidget.normalTextStyle(18.0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantitycontroller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.inventory, color: Colors.green),
                        hintText: "Enter weight in kg (e.g. 1.5)",
                        border: OutlineInputBorder(),
                        suffixText: "kg",
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Points guide and calculation
                    _buildPointsCard(),

                    const SizedBox(height: 30),

                    // Submit
                    GestureDetector(
                      onTap: _loading ? null : _submit,
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width / 1.5,
                        decoration: BoxDecoration(
                          color: _loading ? Colors.grey : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text("Upload", style: AppWidget.whiteTextStyle(22.0)),
                        ),
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

  // UPDATED: Map Widget with polyline from user to selected location
  Widget _buildMapWidget() {
    if (_userPosition == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(_userPosition!.latitude, _userPosition!.longitude),
            initialZoom: 13,
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.recycle_mate',
            ),
            // Polyline from user to selected location
            if (_selectedLocationPoint != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      _selectedLocationPoint!,
                    ],
                    color: Colors.blue,
                    strokeWidth: 3,
                  )
                ],
              ),
            MarkerLayer(
              markers: [
                // User Location (Blue)
                Marker(
                  point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                  ),
                ),
                // Pickup Locations (Green)
                ...pickupLocations.map((loc) {
                  final isSelected = _selectedLocationPoint?.latitude == loc['lat'] &&
                      _selectedLocationPoint?.longitude == loc['lng'];

                  return Marker(
                    point: LatLng(loc['lat'], loc['lng']),
                    width: 50,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected ? Colors.red : Colors.green).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: isSelected ? 3 : 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isSelected ? Icons.location_on : Icons.location_on,
                            color: Colors.white,
                            size: isSelected ? 24 : 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            loc['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLResultCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Prediction Result', style: AppWidget.headlineTextStyle(18.0)),
              ],
            ),
            const SizedBox(height: 12),
            if (_mlResult!.success) ...[
              Text(
                'Detected: ${_mlResult!.category}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                'Confidence: ${(_mlResult!.confidence! * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else ...[
              Text(
                'Detection failed: ${_mlResult!.error}',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    final categories = MLClassificationService.getAvailableCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text("Category:", style: AppWidget.normalTextStyle(18.0)),
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
            value: _selectedCategory,
            underline: const SizedBox(),
            hint: const Text("Select category"),
            items: categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                _onQtyChanged();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Points Guide (per kg)", style: AppWidget.headlineTextStyle(18.0)),
          const SizedBox(height: 12),
          ...(_pointsPerKg.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("• ${entry.key}: ${entry.value.toStringAsFixed(0)} points/kg"),
          ))),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("You will earn:", style: AppWidget.normalTextStyle(16.0)),
              Text(
                "$_totalPoints points",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
