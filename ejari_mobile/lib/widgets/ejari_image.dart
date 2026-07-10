import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../theme/app_theme.dart';

class EjariImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final bool isLocalFile;
  final double? width;
  final double? height;

  const EjariImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.isLocalFile = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocalFile) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        io.File(path),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.backgroundColor,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppTheme.primaryColor),
    );
  }

  /// Returns a decoration image that works on all platforms.
  static DecorationImage decoration({
    required String path,
    BoxFit fit = BoxFit.cover,
    bool isLocalFile = false,
  }) {
    if (!isLocalFile) {
      return DecorationImage(image: AssetImage(path), fit: fit);
    }

    if (kIsWeb) {
      return DecorationImage(image: NetworkImage(path), fit: fit);
    } else {
      return DecorationImage(image: FileImage(io.File(path)), fit: fit);
    }
  }

  /// Returns an ImageProvider that works on all platforms.
  static ImageProvider provider(String path, {bool isLocalFile = false}) {
    if (!isLocalFile) return AssetImage(path);

    if (kIsWeb) {
      return NetworkImage(path);
    } else {
      return FileImage(io.File(path));
    }
  }
}
