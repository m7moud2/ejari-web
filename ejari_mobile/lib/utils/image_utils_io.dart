import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePlatformUtils {
  static Future<String?> saveFileLocally(XFile xFile) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
      final String filePath = p.join(directory.path, fileName);

      final File savedFile = File(filePath);
      await savedFile.writeAsBytes(await xFile.readAsBytes());

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }
}
