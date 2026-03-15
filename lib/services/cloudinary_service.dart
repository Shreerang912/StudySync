import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String cloudName = 'dqi29bjj2';
  static const String uploadPreset = 'studysync_notes';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String;
      } else {
        print('Cloudinary error: ${jsonData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> images) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image);
      if (url != null) urls.add(url);
    }
    return urls;
  }
}