import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../services/data_service.dart';

class ReviewsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const ReviewsScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await DataService.getReviewsForProperty(widget.propertyId);

      setState(() {
        _reviews = reviews;
        _calculateAverage();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateAverage() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      return;
    }

    double sum = 0;
    for (var review in _reviews) {
      sum += review['rating'];
    }
    _averageRating = sum / _reviews.length;
  }

  void _showAddReviewDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة تقييم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('التقييم:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.borderColor,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'التعليق',
                    hintText: 'شاركنا تجربتك...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  final newReview = {
                    'userName': 'أنت',
                    'rating': rating,
                    'comment': commentController.text,
                    'date': DateTime.now().toIso8601String(),
                  };

                  await DataService.addReview(widget.propertyId, newReview);

                  if (context.mounted) {
                    setState(() {
                      _reviews.insert(0, newReview);
                      _calculateAverage();
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم إضافة تقييمك بنجاح! ✅'),
                          backgroundColor: AppTheme.primaryColor),
                    );
                  }
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التقييمات — ${widget.propertyTitle}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Rating Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _averageRating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppTheme.borderColor,
                            size: 28,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'بناءً على ${_reviews.length} ${_reviews.length == 1 ? 'تقييم' : 'تقييمات'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Reviews List
                Expanded(
                  child: _reviews.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) =>
                              _buildReviewCard(_reviews[index], index),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة تقييم'),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  review['userName']?.isNotEmpty == true
                      ? review['userName'][0]
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['userName'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review['rating']
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.borderColor,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _getTimeAgo(DateParsing.parse(review['date']) ?? DateTime.now()),
                style:
                    const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review['comment']),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInteractionButton(
                Icons.thumb_up_off_alt,
                'مفيد (${review['helpfulCount'] ?? (index % 5)})',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('شكراً لمشاركتك! 👍')),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildInteractionButton(
                Icons.reply_rounded,
                'رد المالك',
                () => _showReplyDialog(review['userName']),
              ),
            ],
          ),
          if (review['reply'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.business,
                          size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 6),
                      Text('رد المالك:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review['reply'],
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionButton(
      IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textPrimary),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  void _showReplyDialog(String reviewerName) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الرد على $reviewerName'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(hintText: 'اكتب ردك هنا...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم إرسال ردك بنجاح! 📨'),
                    backgroundColor: AppTheme.primaryColor),
              );
            },
            child: const Text('إرسال الرد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review, size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('لا توجد تقييمات بعد',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
          SizedBox(height: 8),
          Text('كن أول من يضيف تقييماً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else {
      return 'الآن';
    }
  }
}
