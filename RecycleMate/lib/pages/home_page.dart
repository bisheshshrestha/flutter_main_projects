import 'package:flutter/material.dart';
import 'package:recycle_mate/pages/upload_item.dart';
import 'package:recycle_mate/services/database.dart';
import 'package:recycle_mate/services/shared_pref.dart';
import 'package:recycle_mate/services/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? id, name, image;
  Stream? historyStream;

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
      historyStream = await DatabaseMethods().getUserAllRequests(id!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: id == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildBanner(),
              const SizedBox(height: 30),
              _buildSectionTitle("Categories"),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 30),
              _buildSectionTitle("Request History"),
              const SizedBox(height: 16),
              _buildRequestsHistory(),
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
        const SizedBox(width: 12),
        Text("Hello, ", style: AppWidget.headlineTextStyle(26.0)),
        Text(name != null ? name! : "", style: AppWidget.greenTextStyle(25.0)),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFe0f7fa), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset("assets/images/home.png", height: 200, width: MediaQuery.of(context).size.width),
          const SizedBox(height: 10),
          Text("Welcome to Recycle Mate!", style: AppWidget.headlineTextStyle(22.0)),
          const SizedBox(height: 6),
          Text("Recycle your items and earn points.", style: AppWidget.normalTextStyle(16.0)),
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
      {"image": "assets/images/Water Bottle.gif", "label": "Plastic Bottle"},
      {"image": "assets/images/Paper.gif", "label": "Paper"},
      {"image": "assets/images/glass.png", "label": "Glass"},
      {"image": "assets/images/opening cardboard box.gif", "label": "Cardboard"},
      {"image": "assets/images/metal.png", "label": "Metal"},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFececf8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black26, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Image.asset(imagePath, height: 60, width: 60, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppWidget.normalTextStyle(16.0)),
        ],
      ),
    );
  }

  Widget _buildRequestsHistory() {
    if (historyStream == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(12),
      child: StreamBuilder(
        stream: historyStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = List.from(snapshot.data.docs);

          // Safety sort by CreatedAt desc
          docs.sort((a, b) {
            final ta = a.data()?['CreatedAt'];
            final tb = b.data()?['CreatedAt'];
            final ma = ta is Timestamp ? ta.toDate().millisecondsSinceEpoch : 0;
            final mb = tb is Timestamp ? tb.toDate().millisecondsSinceEpoch : 0;
            return mb.compareTo(ma);
          });

          if (docs.isEmpty) {
            return Center(child: Text("No requests yet.", style: AppWidget.normalTextStyle(16.0)));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ds = docs[index];
              return _buildRequestCard(ds);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic ds) {
    final quantity = ds["Quantity"];
    final unit = ds["QuantityUnit"] ?? "kg";
    final quantityText = unit == "piece" ? "${quantity.toInt()} $unit${quantity > 1 ? 's' : ''}" : "$quantity $unit";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFE0F2F1)),
            padding: const EdgeInsets.all(8),
            child: ds["Image"] != null && ds["Image"] != ""
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ds['Image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset("assets/images/chips.png", fit: BoxFit.contain),
              ),
            )
                : Image.asset("assets/images/chips.png", fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ds["Category"] ?? "Unknown",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ds["Address"] ?? "Unknown location",
                        style: AppWidget.normalTextStyle(14.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.scale, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 4),
                    Text(quantityText, style: AppWidget.normalTextStyle(14.0)),
                  ],
                ),
                if (ds["Points"] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber[700], size: 16),
                      const SizedBox(width: 4),
                      Text("${ds["Points"]} points",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _getStatusColor(ds["Status"]), borderRadius: BorderRadius.circular(12)),
            child: Text(
              ds["Status"] ?? "Pending",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusTextColor(ds["Status"])),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green[100]!;
      case 'rejected':
        return Colors.red[100]!;
      case 'pending':
      default:
        return Colors.amber[100]!;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green[800]!;
      case 'rejected':
        return Colors.red[800]!;
      case 'pending':
      default:
        return Colors.orange[800]!;
    }
  }
}