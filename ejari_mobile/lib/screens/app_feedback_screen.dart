import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

class AppFeedbackScreen extends StatefulWidget {
  final bool isGeneral; // true for home banner, false for after-transaction
  const AppFeedbackScreen({super.key, this.isGeneral = true});

  @override
  State<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends State<AppFeedbackScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء اختيار التقييم أولاً ⭐')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await DataService.saveAppFeedback({
      'rating': _rating,
      'comment': _commentController.text,
      'type': widget.isGeneral ? 'general' : 'transaction_complete',
    });

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('شكراً لمساهمتك! ❤️', textAlign: TextAlign.center),
          content: const Text(
            'رأيك يساعدنا في تطوير إيجاري ليكون دائماً عند حسن ظنك ويقدم الخدمة التي تليق بك.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back
                },
                child: const Text('إغلاق'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('رأيك يهمنا ✨'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded,
                size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              widget.isGeneral
                  ? 'ما رأيك في فكرة تطبيق إيجاري؟'
                  : 'كيف كانت تجربتك في إتمام هذه المعاملة؟',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'رأيك يساعدنا على التطوير المستمر لتقديم أفضل خدمة تناسب تطلعاتك.',
              style: TextStyle(color: AppTheme.primaryColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 45,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'ما هي ملاحظاتك أو مقترحاتك لتطوير التطبيق؟',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.borderColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إرسال التقييم',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
