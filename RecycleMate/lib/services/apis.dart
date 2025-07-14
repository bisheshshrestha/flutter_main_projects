// lib/services/apis.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageKitApi {
  static const String uploadUrl = "https://upload.imagekit.io/api/v1/files/upload";
  static const String privateApiKey = "private_HLBI8CGUr03E6vM405+frtcc55g=";
  static const String folder = "/recyclemate_uploads";

  static Future<String?> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers['Authorization'] =
          'Basic ' + base64Encode(utf8.encode('$privateApiKey:'));

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['fileName'] = file.path.split('/').last;
      request.fields['folder'] = folder;

      var response = await request.send();
      if (response.statusCode == 200) {
        var resStr = await response.stream.bytesToString();
        var resJson = json.decode(resStr);
        return resJson['url'];
      } else {
        print("Upload failed: ${response.statusCode}");
        print(await response.stream.bytesToString());
      }
    } catch (e) {
      print("Error uploading to ImageKit: $e");
    }
    return null;
  }
}
