import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dqi29bjj2';
  static const String uploadPreset = 'studysync_notes';

  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
          'file', bytes, filename: imageFile.name));
      final response = await request.send();
      final data = json.decode(await response.stream.bytesToString());
      if (response.statusCode == 200) return data['secure_url'] as String;
      return null;
    } catch (e) {
      return null;
    }
  }
}
