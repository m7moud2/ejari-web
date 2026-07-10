import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/check_in_out_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ejari_section.dart';

/// مطالبة أضرار من المالك — صور قبل/بعد.
class DamageClaimScreen extends StatefulWidget {
  final String bookingId;
  final String ownerEmail;

  const DamageClaimScreen({
    super.key,
    required this.bookingId,
    required this.ownerEmail,
  });

  @override
  State<DamageClaimScreen> createState() => _DamageClaimScreenState();
}

class _DamageClaimScreenState extends State<DamageClaimScreen> {
  final _descController = TextEditingController();
  final _beforePhotos = <String>[];
  final _afterPhotos = <String>[];
  bool _submitting = false;

  Future<void> _capture(List<String> target) async {
    final picked = await ImageUtils.pickAndCompress(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked != null) {
      setState(() => target.add(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى وصف الأضرار')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await CheckInOutService.submitDamageClaim(
      bookingId: widget.bookingId,
      ownerEmail: widget.ownerEmail,
      beforePhotos: _beforePhotos,
      afterPhotos: _afterPhotos,
      description: _descController.text.trim(),
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? 'تم')),
    );
    if (result['success'] == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مطالبة أضرار'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [
          const EjariSurfaceCard(
            elevated: false,
            child: Text(
              'صوّر الوحدة قبل وبعد — العربون يُحجز حتى مراجعة المطالبة.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          _photoSection('صور قبل', _beforePhotos),
          const SizedBox(height: 12),
          _photoSection('صور بعد', _afterPhotos),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'وصف الأضرار',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Text('تقديم المطالبة'),
          ),
        ],
      ),
    );
  }

  Widget _photoSection(String title, List<String> photos) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...photos.map((p) => Chip(label: Text(p.split('/').last))),
              ActionChip(
                avatar: const Icon(Icons.camera_alt, size: 16),
                label: const Text('التقاط'),
                onPressed: () => _capture(photos),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
