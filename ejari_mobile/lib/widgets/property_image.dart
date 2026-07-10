import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/property_image_resolver.dart';
import 'ejari_image.dart';

/// Unified property image with shimmer placeholder and type-aware fallback.
class PropertyImage extends StatelessWidget {
  final String? imagePath;
  final Map<String, dynamic>? property;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PropertyImage({
    super.key,
    this.imagePath,
    this.property,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool _isNetwork(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String get _resolvedPath {
    if (imagePath != null && imagePath!.trim().isNotEmpty) {
      return PropertyImageResolver.resolvePath(imagePath, property: property);
    }
    return PropertyImageResolver.resolve(property);
  }

  @override
  Widget build(BuildContext context) {
    final path = _resolvedPath;
    Widget image;

    if (_isNetwork(path)) {
      image = CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _ShimmerBox(width: width, height: height),
        errorWidget: (context, url, error) => EjariImage(
          path: PropertyImageResolver.resolve(property),
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else {
      image = EjariImage(
        path: path,
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;

  const _ShimmerBox({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.06),
            AppTheme.primaryColor.withOpacity(0.14),
            AppTheme.primaryColor.withOpacity(0.06),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_work_outlined,
            color: AppTheme.primaryColor, size: 28),
      ),
    );
  }
}
