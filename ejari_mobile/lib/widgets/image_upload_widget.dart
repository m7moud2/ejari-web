import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';
import 'ejari_image.dart';

class ImageUploadWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function(String) onImageSelected;

  const ImageUploadWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onImageSelected,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImageUtils.pickAndCompress(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile.path;
      });
      widget.onImageSelected(_selectedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primaryColor, style: BorderStyle.solid),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                        image: EjariImage.provider(_selectedImage!,
                            isLocalFile: true),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 40, color: AppTheme.primaryColor),
                  const SizedBox(height: 8),
                  Text(widget.label,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
      ),
    );
  }
}
