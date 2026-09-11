import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<Map<String, dynamic>?> pickReceiptImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      final Uint8List bytes = await image.readAsBytes();
      
      // Auto downscale fallback agar file 1MB se badi ho
      final String base64String = base64Encode(bytes);
      final String fileName = image.name.isNotEmpty 
          ? image.name 
          : 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      const String mimeType = 'image/jpeg';

      return {
        'fileName': fileName,
        'mimeType': mimeType,
        'size': bytes.length,
        'base64': 'data:$mimeType;base64,$base64String',
      };
    } catch (e) {
      debugPrint('Camera/Gallery Picker Error: $e');
      return null;
    }
  }

  // Android low-memory recovery
  static Future<Map<String, dynamic>?> retrieveLostData() async {
    if (kIsWeb) return null;
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return null;

      final bytes = await response.file!.readAsBytes();
      final base64String = base64Encode(bytes);
      return {
        'fileName': response.file!.name,
        'mimeType': 'image/jpeg',
        'size': bytes.length,
        'base64': 'data:image/jpeg;base64,$base64String',
      };
    } catch (e) {
      return null;
    }
  }
}
