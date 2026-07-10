import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ejari_image.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  String? _profileImagePath;
  bool _isLocalImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() {
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _profileImagePath = user['image']; // Assume 'image' field exists
        _isLocalImage = _profileImagePath != null &&
            !_profileImagePath!.startsWith('assets/');
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final xFile = await ImageUtils.pickAndCompress(source: source);
    if (xFile != null) {
      setState(() {
        _profileImagePath = xFile.path;
        _isLocalImage = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await AuthService.updateProfile({
        'email': _emailController.text,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'image': _profileImagePath,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم تحديث البيانات بنجاح ✅'),
                backgroundColor: AppTheme.primaryColor),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('حدث خطأ أثناء التحديث ❌'),
                backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          backgroundImage: _profileImagePath != null
                              ? EjariImage.provider(_profileImagePath!,
                                  isLocalFile: _isLocalImage)
                              : null,
                          child: _profileImagePath == null
                              ? const Icon(Icons.person,
                                  size: 50, color: AppTheme.primaryColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Container(
                                    decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).cardTheme.color ??
                                                Theme.of(context).cardColor,
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(32))),
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('تغيير صورة الملف الشخصي',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 24),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.photo_library_rounded,
                                              color: AppTheme.primaryColor),
                                          title: const Text('اختيار من المعرض'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _pickProfileImage(
                                                ImageSource.gallery);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppTheme.primaryColor),
                                          title: const Text('التقاط صورة'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _pickProfileImage(
                                                ImageSource.camera);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email),
                      ),
                      readOnly: true, // Email usually can't be changed easily
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('حفظ التغييرات',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
