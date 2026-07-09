import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_reviews_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _appRating = 0;
  int _serviceRating = 0;
  final TextEditingController _opinionController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();
  bool _isSubmitting = false;

  void _submitFeedback() async {
    if (_appRating == 0 || _serviceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تقييم التطبيق والخدمة أولاً ⭐️')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Save to Firebase
    bool success = await FirestoreReviewsService.submitFeedback(
      appRating: _appRating,
      serviceRating: _serviceRating,
      opinion: _opinionController.text,
      suggestion: _suggestionController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('حدث خطأ أثناء الإرسال. يرجى المحاولة لاحقاً')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite,
                  color: AppTheme.primaryColor, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'شكراً لمشاركتنا رأيك!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'رأيك يهمنا جداً في تحسين تجربة إيجاري وتطوير خدماتنا باستمرار.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('العودة للرئيسية',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(
      String title, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => onRatingChanged(index + 1),
              icon: Icon(
                index < currentRating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color:
                    index < currentRating ? Colors.amber : AppTheme.borderColor,
                size: 36,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('شاركنا رأيك',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights_rounded,
                          color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('ملاحظاتك تصنع الفرق',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'قيّم التجربة بسرعة، وأضف رأيك أو اقتراحك لنستمر في تحسين التطبيق بشكل عملي.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'نحن نستمع إليك! 💡',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'تقييمك ومقترحاتك تساعدنا في تطوير التطبيق لتقديم أفضل خدمة ممكنة لتسهيل إيجار الشقق.',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('سهولة الاستخدام', () {
                  _opinionController.text = 'التطبيق سهل وواضح ومريح في الاستخدام.';
                }),
                _buildQuickChip('الثقة والأمان', () {
                  _opinionController.text = 'أحتاج وضوحًا أكبر في خطوات الدفع والعقد.';
                }),
                _buildQuickChip('تحسينات مقترحة', () {
                  _suggestionController.text =
                      'أقترح إضافة تنبيهات أوضح ولوحة متابعة أسرع.';
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Ratings
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(
                      'ما هو تقييمك لتجربة استخدام التطبيق؟', _appRating,
                      (rating) {
                    setState(() => _appRating = rating);
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  _buildStarRating(
                      'ما هو تقييمك لجودة العقارات والخدمات؟', _serviceRating,
                      (rating) {
                    setState(() => _serviceRating = rating);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Text Fields
            const Text('رأيك الشخصي (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _opinionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'أخبرنا عن تجربتك بشكل عام...',
                hintStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('مقترحات للتحسين (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _suggestionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'هل لديك أفكار أو ميزات تود رؤيتها في التطبيق؟',
                hintStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('إرسال التقييم',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
      labelStyle: const TextStyle(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
