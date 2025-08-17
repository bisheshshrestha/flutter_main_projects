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

  Future rejectAdminRequest(String id) async{
    return await FirebaseFirestore.instance
        .collection("requests")
        .doc(id)
        .update({"Status":"Rejected"});
  }

  Future rejectUserRequest(String id, String itemId) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("items").doc(itemId)
        .update({"Status":"Rejected"});
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

  Future<Stream<QuerySnapshot>> getAdminReedemApproval() async{
    return await FirebaseFirestore.instance
        .collection("redeem")
        .where("Status",isEqualTo: "Pending")
        .snapshots();
  }

  Future updateAdminReedemRequests(String id) async{
    return await FirebaseFirestore.instance
        .collection("redeem")
        .doc(id)
        .update({"Status":"Approved"});
  }

  Future updateUserReedemRequests(String id, String itemId) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("redeem")
        .doc(itemId)
        .update({"Status":"Approved"});
  }


  Future<Stream<QuerySnapshot>> getUserPendingRequests(String id) async{
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("items")
        .where("Status",isEqualTo: "Pending")
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getUserAllRequests(String id) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("items")
        .orderBy("CreatedAt", descending: true)
        .snapshots();
  }
}