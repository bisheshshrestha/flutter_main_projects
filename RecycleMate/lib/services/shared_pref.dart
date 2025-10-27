// File: lib/services/shared_pref.dart

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const String userIdKey = "USERKEY";
  static const String userNameKey = "USERNAMEKEY";
  static const String userEmailKey = "USEREMAILKEY";
  static const String userImageKey = "USERIMAGEKEY";
  static const String userRoleKey = "USERROLEKEY";

  Future<bool> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, id);
  }

  Future<bool> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, name);
  }

  Future<bool> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, email);
  }

  Future<bool> saveUserImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageKey, imageUrl);
  }

  Future<bool> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userRoleKey, role);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userRoleKey);
  }

  Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  Future<bool> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(userRoleKey);
  }
}
