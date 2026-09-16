import "dart:convert";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:universal_html/html.dart" as html;

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> showImageSourceDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Select Attachment Source"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xffEFF6FF),
                  child: Icon(Icons.camera_alt, color: Color(0xff2563EB)),
                ),
                title: const Text("Take Photo (Camera)"),
                onTap: () async {
                  final result = await _pickAction(ImageSource.camera);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(result);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xffFAF5FF),
                  child: Icon(Icons.photo_library_outlined, color: Colors.purple),
                ),
                title: const Text("Upload from Gallery"),
                onTap: () async {
                  final result = await _pickAction(ImageSource.gallery);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(result);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<String?> pickImage(ImageSource source) async {
    return _pickAction(source);
  }

  static ImageProvider? getAvatarImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
    final trimmed = avatarUrl.trim();
    if (trimmed.startsWith('data:image') || (!trimmed.startsWith('http://') && !trimmed.startsWith('https://') && trimmed.length > 80)) {
      try {
        String cleanBase64 = trimmed;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.substring(cleanBase64.indexOf(',') + 1);
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        while (cleanBase64.length % 4 != 0) {
          cleanBase64 += '=';
        }
        final bytes = base64Decode(cleanBase64);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint("Error decoding avatar base64: $e");
        return null;
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    return null;
  }

  static Future<String?> _pickAction(ImageSource source) async {
    try {
      if (kIsWeb) {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = "image/*";
        if (source == ImageSource.camera) {
          uploadInput.setAttribute("capture", "environment");
        }
        uploadInput.click();

        await uploadInput.onChange.first;
        if (uploadInput.files == null || uploadInput.files!.isEmpty) return null;

        final file = uploadInput.files![0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        return reader.result as String?;
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (image == null) return null;
        final bytes = await image.readAsBytes();
        return "data:image/jpeg;base64,${base64Encode(bytes)}";
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      return null;
    }
  }
}
