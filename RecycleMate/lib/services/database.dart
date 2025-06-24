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

  Future<Stream<QuerySnapshot>> getAdminApproval() async{
    return await FirebaseFirestore.instance
        .collection("requests")
        .where("Status",isEqualTo: "Pending")
        .snapshots();
  }

  Future updateAdminRequests(String id) async{
    return await FirebaseFirestore.instance
        .collection("requests")
        .doc(id)
        .update({"Status":"Approved"});
  }

  Future updateUserRequests(String id, String itemId) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("items").doc(itemId)
        .update({"Status":"Approved"});
  }

  Future updateUserPoints(String id, String points) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"points":points});
  }

  Future addUserRedeemPoints(Map<String, dynamic> userInfoMap, String id, String redeemId) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("redeem")
        .doc(redeemId)
        .set(userInfoMap);
  }

  Future addAdminRedeemRequests(Map<String, dynamic> userInfoMap, String reedemId) async{
    return await FirebaseFirestore.instance
        .collection("redeem")
        .doc(reedemId)
        .set(userInfoMap);
  }


  Future<Stream<QuerySnapshot>> getUserTransactions(String id) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("redeem")
        .snapshots();
  }
}
