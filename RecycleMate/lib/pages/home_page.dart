import 'package:flutter/material.dart';
import 'package:recycle_mate/pages/profile.dart';
import 'package:recycle_mate/pages/upload_item.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? id, name, image;
  Stream? pendingStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    id = await SharedPreferenceHelper().getUserId();
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    if (id != null) {
      pendingStream = await DatabaseMethods().getUserPendingRequests(id!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: id == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 30),
              _buildBanner(),
              SizedBox(height: 30),
              _buildSectionTitle("Categories"),
              SizedBox(height: 16),
              _buildCategories(),
              SizedBox(height: 30),
              _buildSectionTitle("Pending Requests"),
              SizedBox(height: 16),
              _buildPendingRequests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset("assets/images/wave.png", height: 30, width: 30),
        SizedBox(width: 12),
        Text("Hello, ", style: AppWidget.headlineTextStyle(26.0)),
        Text(name != null ? name!.split(" ")[0] : "", style: AppWidget.greenTextStyle(25.0)),
        Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image != null && image!.isNotEmpty
              ? Image.network(image!, height: 48, width: 48, fit: BoxFit.cover)
              : Image.asset("assets/images/boy.jpg", height: 48, width: 48, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFFe0f7fa),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset("assets/images/home.png", height: 200, width: MediaQuery.of(context).size.width),
          SizedBox(height: 10),
          Text(
            "Welcome to Recycle Mate!",
            style: AppWidget.headlineTextStyle(22.0),
          ),
          SizedBox(height: 6),
          Text(
            "Recycle your items and earn points.",
            style: AppWidget.normalTextStyle(16.0),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(title, style: AppWidget.headlineTextStyle(20.0)),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {"image": "assets/images/plastic.png", "label": "Plastic Bottle"},
      {"image": "assets/images/paper.png", "label": "Paper"},
      // {"image": "assets/images/battery.png", "label": "Battery"},
      {"image": "assets/images/glass.png", "label": "Glass"},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 18),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildCategoryItem(cat["image"]!, cat["label"]!);
        },
      ),
    );
  }

  Widget _buildCategoryItem(String imagePath, String label) {
    return GestureDetector(
      onTap: () {
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadItem(category: label, id: id!),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFececf8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black26, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(imagePath, height: 60, width: 60, fit: BoxFit.cover),
          ),
          SizedBox(height: 8),
          Text(label, style: AppWidget.normalTextStyle(16.0)),
        ],
      ),
    );
  }

  Widget _buildPendingRequests() {
    if (pendingStream == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.all(12),
      child: StreamBuilder(
        stream: pendingStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data.docs.isEmpty) {
            return Center(
              child: Text(
                "No pending requests.",
                style: AppWidget.normalTextStyle(16.0),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data.docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ds = snapshot.data.docs[index];
              return _buildPendingRequestCard(ds);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestCard(dynamic ds) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Left thumbnail
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0xFFE0F2F1),
            ),
            padding: EdgeInsets.all(8),
            child: ds["Image"] != "" ?
              Image.network(ds['Image'])
                : Image.asset("assets/images/chips.png", fit: BoxFit.contain),
            // child: Image.asset("assets/images/chips.png", fit: BoxFit.contain),
          ),

          SizedBox(width: 16),

          // Middle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[600], size: 20),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ds["Address"],
                        style: AppWidget.normalTextStyle(16.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.layers, color: Colors.orange[700], size: 20),
                    SizedBox(width: 6),
                    Text(
                      "${ds["Quantity"]}",
                      style: AppWidget.normalTextStyle(16.0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Optional status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Pending",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

}