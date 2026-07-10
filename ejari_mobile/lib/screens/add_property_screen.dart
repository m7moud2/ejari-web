import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/property_provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/subscription_service.dart';
import '../models/accommodation_type.dart';
import 'listing_plans_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddPropertyScreen({super.key, this.initialData});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  double price = 0.0;
  String city = '';
  String _listingMode = 'rent';
  AccommodationType _accommodationType = AccommodationType.fullUnit;
  int _totalBeds = 2;
  int _totalRooms = 1;
  double _priceDaily = 0;
  double _priceWeekly = 0;
  double _priceMonthly = 0;
  double _seasonalRate = 0;
  bool _useManualPricing = false;

  File? _selectedImage;
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
    if (widget.initialData != null) {
      title = widget.initialData!['title'] ?? '';
      description = widget.initialData!['description'] ?? '';
      price = (widget.initialData!['price'] ?? 0).toDouble();
      city = widget.initialData!['location'] ?? '';
      _accommodationType = accommodationTypeFromProperty(widget.initialData!);
      _totalBeds = (widget.initialData!['totalBeds'] as num?)?.toInt() ??
          int.tryParse(widget.initialData!['beds']?.toString() ?? '2') ??
          2;
      _totalRooms = (widget.initialData!['totalRooms'] as num?)?.toInt() ?? 1;
      final dp = widget.initialData!['dynamicPricing'] as Map<String, dynamic>?;
      if (dp != null) {
        _useManualPricing = dp['useManual'] == true;
        _priceDaily = (dp['daily'] as num?)?.toDouble() ?? 0;
        _priceWeekly = (dp['weekly'] as num?)?.toDouble() ?? 0;
        _priceMonthly = (dp['monthly'] as num?)?.toDouble() ?? price;
        _seasonalRate = (dp['seasonalRate'] as num?)?.toDouble() ?? 0;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedVideo = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _loadSubscription() async {
    final info = await SubscriptionService.checkListingAbility();
    if (mounted) setState(() => _subscriptionInfo = info);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final canAdd = await SubscriptionService.canAddProperty();
    if (!canAdd) {
      if (!mounted) return;
      final upgrade = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('وصلت لحد الباقة'),
          content: Text(
            'باقتك الحالية (${_subscriptionInfo?['current_plan']}) تسمح بـ '
            '${_subscriptionInfo?['limit']} عقار فقط. ترقِّ باقتك للمتابعة.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('عرض الباقات'),
            ),
          ],
        ),
      );
      if (upgrade == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ListingPlansScreen()));
        await _loadSubscription();
      }
      return;
    }

    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? user?['uid']?.toString() ?? 'owner@ejari.app';
    final autoFeature = await SubscriptionService.shouldAutoFeature();

    final bedUnits = List.generate(_totalBeds, (i) {
      final roomIndex = i ~/ (_totalBeds / _totalRooms).ceil().clamp(1, _totalBeds);
      return {
        'id': 'bed_${i + 1}',
        'roomId': 'room_${String.fromCharCode(97 + roomIndex.clamp(0, 25))}',
        'label': 'سرير ${i + 1}',
        'status': 'vacant',
      };
    });
    final roomUnits = List.generate(_totalRooms, (i) => {
          'id': 'room_${String.fromCharCode(97 + i)}',
          'label': 'غرفة ${String.fromCharCode(65 + i)}',
          'bedCount': (_totalBeds / _totalRooms).ceil(),
          'occupiedBeds': 0,
          'status': 'vacant',
        });

    final monthlyPrice = _useManualPricing && _priceMonthly > 0
        ? _priceMonthly
        : price;

    final newProperty = {
      'title': title,
      'description': description,
      'price': monthlyPrice.toStringAsFixed(0),
      'type': _accommodationType == AccommodationType.fullUnit
          ? 'شقق'
          : 'سكن مشترك',
      'listingMode': _listingMode,
      'accommodationType': _accommodationType.value,
      'location': city,
      'governorate': city.split('،').last.trim(),
      'image': _selectedImage?.path ?? 'assets/images/home1.jpg',
      'beds': _totalBeds.toString(),
      'baths': '1',
      'area': '120',
      'totalBeds': _totalBeds,
      'totalRooms': _totalRooms,
      'bedUnits': bedUnits,
      'roomUnits': roomUnits,
      'ownerId': ownerId,
      'ownerEmail': ownerId,
      'features': {'bedrooms': _totalBeds, 'bathrooms': 1, 'area': 120},
      'status': 'pending',
      'isFeatured': autoFeature,
      'supportedDurations': _listingMode == 'for_sale'
          ? <String>[]
          : ['يوم', 'أسبوع', 'شهر'],
      if (_useManualPricing)
        'dynamicPricing': {
          'daily': _priceDaily,
          'weekly': _priceWeekly,
          'monthly': _priceMonthly > 0 ? _priceMonthly : monthlyPrice,
          'seasonalRate': _seasonalRate > 0 ? _seasonalRate : null,
          'seasonalLabel': 'سعر موسمي',
          'useManual': true,
        },
      if (_accommodationType != AccommodationType.fullUnit)
        'perBedPricing': {
          'daily': _priceDaily > 0 ? _priceDaily : monthlyPrice * 0.05,
          'weekly': _priceWeekly > 0 ? _priceWeekly : monthlyPrice * 0.28,
          'monthly': monthlyPrice,
        },
      'depositAmount': (monthlyPrice * 0.2).toStringAsFixed(0),
    };

    if (!mounted) return;
    final propertyProvider = context.read<PropertyProvider>();
    try {
      await DataService.addProperty(newProperty);
      await propertyProvider.fetchAllProperties();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعلان بنجاح وسيظهر بعد المراجعة!'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _formKey.currentState?.reset();
        setState(() {
          title = '';
          description = '';
          price = 0.0;
          city = '';
          _listingMode = 'rent';
          _selectedImage = null;
          _selectedVideo = null;
        });
        await _loadSubscription();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('نشر إعلان عقاري جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_subscriptionInfo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'باقتك: ${_subscriptionInfo!['current_plan']} — '
                        '${_subscriptionInfo!['current_count']}/${_subscriptionInfo!['limit'] == -1 ? '∞' : _subscriptionInfo!['limit']} عقار',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  _buildSectionTitle('نوع الإعلان'),
                  Row(
                    children: [
                      Expanded(child: _modeChip('rent', 'للإيجار')),
                      const SizedBox(width: 10),
                      Expanded(child: _modeChip('for_sale', 'للبيع')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_listingMode == 'rent') ...[
                    _buildSectionTitle('نوع الوحدة'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AccommodationType.values.map((t) {
                        final selected = _accommodationType == t;
                        return ChoiceChip(
                          label: Text(t.arabicLabel),
                          selected: selected,
                          selectedColor:
                              AppTheme.primaryColor.withOpacity(0.15),
                          onSelected: (_) =>
                              setState(() => _accommodationType = t),
                        );
                      }).toList(),
                    ),
                    if (_accommodationType != AccommodationType.fullUnit) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'عدد الأسرّة',
                              hint: '8',
                              initialValue: _totalBeds.toString(),
                              isNumber: true,
                              onSaved: (v) =>
                                  _totalBeds = int.tryParse(v ?? '') ?? 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'عدد الغرف',
                              hint: '4',
                              initialValue: _totalRooms.toString(),
                              isNumber: true,
                              onSaved: (v) =>
                                  _totalRooms = int.tryParse(v ?? '') ?? 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('تسعير يدوي (يومي/أسبوعي/شهري)'),
                      subtitle: const Text('أو اتركه للتسعير التلقائي'),
                      value: _useManualPricing,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => _useManualPricing = v),
                    ),
                    if (_useManualPricing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'يومي (ج.م)',
                              hint: '150',
                              initialValue: _priceDaily > 0
                                  ? _priceDaily.toStringAsFixed(0)
                                  : '',
                              isNumber: true,
                              onSaved: (v) =>
                                  _priceDaily = double.tryParse(v ?? '') ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              label: 'أسبوعي (ج.م)',
                              hint: '800',
                              initialValue: _priceWeekly > 0
                                  ? _priceWeekly.toStringAsFixed(0)
                                  : '',
                              isNumber: true,
                              onSaved: (v) =>
                                  _priceWeekly = double.tryParse(v ?? '') ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'سعر موسمي (اختياري)',
                        hint: '2800',
                        initialValue: _seasonalRate > 0
                            ? _seasonalRate.toStringAsFixed(0)
                            : '',
                        isNumber: true,
                        onSaved: (v) =>
                            _seasonalRate = double.tryParse(v ?? '') ?? 0,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle('المعلومات الأساسية'),
                  _buildTextField(
                    label: 'عنوان الإعلان',
                    hint: 'مثال: شقة للبيع بالمعادي - تشطيب سوبر لوكس',
                    initialValue: title,
                    onSaved: (val) => title = val!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'المدينة / المنطقة',
                    hint: 'مثال: القاهرة، المعادي',
                    initialValue: city,
                    onSaved: (val) => city = val!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: _listingMode == 'for_sale' ? 'سعر البيع (ج.م)' : 'الإيجار الشهري (ج.م)',
                    hint: 'مثال: 500000',
                    initialValue: price == 0.0 ? '' : price.toString(),
                    isNumber: true,
                    onSaved: (val) => price = double.tryParse(val!) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'الوصف التفصيلي',
                    hint: 'اذكر مميزات العقار، المساحة، التشطيب...',
                    initialValue: description,
                    maxLines: 4,
                    onSaved: (val) => description = val!,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('الوسائط والصور'),
                  _buildMediaPicker(),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('تأكيد ونشر الإعلان',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String initialValue,
    required Function(String?) onSaved,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildMediaPicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Picker
          const Text('صور العقار (رئيسية)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!,
                      height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor, size: 20),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildMediaButton(
                    icon: Icons.camera_alt_rounded,
                    title: 'تصوير',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaButton(
                    icon: Icons.photo_library_rounded,
                    title: 'المعرض',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Video Picker
          const Text('فيديو تعريفي (اختياري)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_selectedVideo != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_file_rounded,
                      color: AppTheme.primaryColor, size: 30),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('تم اختيار الفيديو بنجاح',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.errorColor),
                    onPressed: () => setState(() => _selectedVideo = null),
                  ),
                ],
              ),
            )
          else
            _buildMediaButton(
              icon: Icons.video_call_rounded,
              title: 'إرفاق فيديو من المعرض',
              onTap: _pickVideo,
              isFullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _modeChip(String mode, String label) {
    final selected = _listingMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _listingMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor.withOpacity(0.3),
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Widget _buildMediaButton(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isFullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
