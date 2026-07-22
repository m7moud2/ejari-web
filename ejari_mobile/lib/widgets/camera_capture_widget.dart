import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';
import 'ejari_image.dart';

/// Camera-only capture widget for identity verification steps.
class CameraCaptureWidget extends StatefulWidget {
  final String label;
  final String captureHint;
  final IconData icon;
  final bool useFrontCamera;
  final ValueChanged<String?> onImageCaptured;
  final String? initialImage;

  const CameraCaptureWidget({
    super.key,
    required this.label,
    required this.captureHint,
    required this.icon,
    required this.onImageCaptured,
    this.useFrontCamera = false,
    this.initialImage,
  });

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget> {
  String? _capturedImage;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImage;
  }

  Future<void> _captureImage() async {
    final picked = await ImageUtils.pickAndCompress(
      source: ImageSource.camera,
      preferredCameraDevice:
          widget.useFrontCamera ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final encoded = base64Encode(bytes);

    setState(() => _capturedImage = encoded);
    widget.onImageCaptured(encoded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _captureImage,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _capturedImage != null
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor.withOpacity(0.5),
              ),
            ),
            child: _capturedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: VerificationImage(data: _capturedImage!),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'إعادة التقاط',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 40, color: AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        widget.captureHint,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'التقط صورة',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Displays verification images stored as base64 or local file paths.
class VerificationImage extends StatelessWidget {
  final String data;
  final BoxFit fit;
  final double? width;
  final double? height;

  const VerificationImage({
    super.key,
    required this.data,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  /// JPEG/PNG/GIF base64 often starts with `/9j/`, `iVBOR`, `R0lGOD` —
  /// must not be treated as filesystem paths.
  bool get _looksLikeBase64 {
    final trimmed = data.trim();
    if (trimmed.startsWith('data:image')) return true;
    if (trimmed.startsWith('/9j/')) return true; // JPEG
    if (trimmed.startsWith('iVBOR')) return true; // PNG
    if (trimmed.startsWith('R0lGOD')) return true; // GIF
    if (trimmed.startsWith('UklGR')) return true; // WEBP
    // Long payloads without path separators are almost certainly base64.
    if (trimmed.length > 256 &&
        !trimmed.contains('/') &&
        !trimmed.contains('\\')) {
      return true;
    }
    return false;
  }

  bool get _isLocalPath {
    final trimmed = data.trim();
    if (_looksLikeBase64) return false;
    if (trimmed.startsWith('file:')) return true;
    if (trimmed.contains(':\\')) return true;
    // Real device paths: /data/, /storage/, /var/, /Users/, etc.
    if (trimmed.startsWith('/') &&
        trimmed.length < 512 &&
        (trimmed.contains('/data/') ||
            trimmed.contains('/storage/') ||
            trimmed.contains('/var/') ||
            trimmed.contains('/Users/') ||
            trimmed.contains('/tmp/') ||
            trimmed.contains('/cache/'))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = data.trim();
    if (_isLocalPath) {
      final path = trimmed.startsWith('file://')
          ? Uri.parse(trimmed).toFilePath()
          : trimmed;
      return EjariImage(
        path: path,
        isLocalFile: true,
        fit: fit,
        width: width,
        height: height,
      );
    }

    try {
      final payload = trimmed.startsWith('data:image')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      final bytes = base64Decode(payload);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.backgroundColor,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppTheme.primaryColor),
    );
  }
}
