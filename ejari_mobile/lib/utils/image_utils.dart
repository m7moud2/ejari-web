import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// Note: Conditional imports to handle dart:io safely
import 'image_utils_stub.dart'
    if (dart.library.io) 'image_utils_io.dart'
    if (dart.library.html) 'image_utils_web.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Picks and compresses an image from Gallery or Camera.
  /// Resulting image will be cross-platform compatible (XFile).
  static Future<XFile?> pickAndCompress({
    ImageSource source = ImageSource.gallery,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 70,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      if (kDebugMode) {
        final length = await pickedFile.length();
        print(
            '📸 Image Picked: ${pickedFile.name} (${(length / 1024).toStringAsFixed(2)} KB)');
      }

      return pickedFile;
    } catch (e) {
      if (kDebugMode) print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Saves to local storage (Mobile only). Returns null on Web.
  static Future<String?> saveLocally(XFile xFile) async {
    return ImagePlatformUtils.saveFileLocally(xFile);
  }
}
