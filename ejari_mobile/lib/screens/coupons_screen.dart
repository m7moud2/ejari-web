import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final TextEditingController _couponController = TextEditingController();

  final List<Map<String, dynamic>> _availableCoupons = [
    {
      'code': 'WELCOME20',
      'discount': '20%',
      'title': 'خصم ترحيبي',
      'description': 'خصم 20% على أول حجز',
      'expiry': '2024-12-31',
      'minAmount': '1000',
      'isUsed': false,
      'type': 'percentage',
    },
    {
      'code': 'SUMMER50',
      'discount': '50 ج.م',
      'title': 'عرض الصيف',
      'description': 'خصم 50 جنيه على أي حجز',
      'expiry': '2024-08-31',
      'minAmount': '500',
      'isUsed': false,
      'type': 'fixed',
    },
    {
      'code': 'PREMIUM10',
      'discount': '10%',
      'title': 'خصم الباقة المميزة',
      'description': 'خصم 10% على اشتراك الباقة الذهبية',
      'expiry': '2024-12-31',
      'minAmount': '0',
      'isUsed': true,
      'type': 'percentage',
    },
    {
      'code': 'FRIEND100',
      'discount': '100 ج.م',
      'title': 'إحالة صديق',
      'description': 'خصم 100 جنيه عند إحالة صديق',
      'expiry': '2024-12-31',
      'minAmount': '1000',
      'isUsed': false,
      'type': 'fixed',
    },
  ];

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كود الكوبون')),
      );
      return;
    }

    final coupon = _availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );

    if (coupon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كود الكوبون غير صحيح'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (coupon['isUsed'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استخدام هذا الكوبون من قبل'),
          backgroundColor: AppTheme.borderColor,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تفعيل الكوبون: ${coupon['discount']} خصم'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    _couponController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الكوبونات والخصومات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Apply Coupon Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لديك كوبون؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل الكود للحصول على خصم فوري',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            hintText: 'أدخل كود الكوبون',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تطبيق',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Available Coupons
            const Text(
              'الكوبونات المتاحة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...List.generate(
              _availableCoupons.length,
              (index) => _buildCouponCard(_availableCoupons[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isUsed = coupon['isUsed'] == true;
    final isPercentage = coupon['type'] == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUsed
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.3),
        ),
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          // Dotted line decoration
          Positioned(
            right: 100,
            top: 0,
            bottom: 0,
            child: CustomPaint(
              painter: DottedLinePainter(),
              size: const Size(1, double.infinity),
            ),
          ),

          Row(
            children: [
              // Left side - Discount
              Container(
                width: 100,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPercentage ? Icons.percent : Icons.attach_money,
                      color: isUsed
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coupon['discount'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isUsed
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'خصم',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUsed
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side - Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              coupon['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUsed
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'مستخدم',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isUsed
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isUsed
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'صالح حتى ${coupon['expiry']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isUsed
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!isUsed)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      coupon['code'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: coupon['code']),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('تم نسخ الكود'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
