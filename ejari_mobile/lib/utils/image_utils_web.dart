import 'package:image_picker/image_picker.dart';

class ImagePlatformUtils {
  static Future<String?> saveFileLocally(XFile xFile) async {
    // Web handles files differently (Blob URLs)
    // No need to save to local documents directory on web
    return xFile.path;
  }
}
