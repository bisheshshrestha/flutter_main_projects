import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserInfo(Map<String, dynamic> userInfoMap, String id) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future addUserUploadItem(Map<String, dynamic> userInfoMap, String id, String itemId) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id).collection("items").doc(itemId)
        .set(userInfoMap);
  }

  Future addAdminItem(Map<String, dynamic> userInfoMap, String id) async{
    return await FirebaseFirestore.instance
        .collection("requests")
        .doc(id)
        .set(userInfoMap);
  }
}
