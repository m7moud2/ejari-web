import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import 'contract_view_screen.dart';
import 'payment_screen.dart';
import 'chat_details_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await DataService.getBookings();
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجوزاتي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد حجوزات حالياً',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'pending';
    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.borderColor;
        statusText = 'قيد الانتظار';
        break;
      case 'viewing_scheduled':
      case 'deposit_paid':
        statusColor = AppTheme.primaryColor;
        statusText = 'عربون المعاينة';
        break;
      case 'approved': // Was accepted
        statusColor = AppTheme.primaryColor;
        statusText = 'تمت الموافقة';
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusText = 'مرفوض';
        break;
      case 'active':
      case 'paid':
        statusColor = AppTheme.primaryColor;
        statusText = 'نشط / مدفوع';
        break;
      case 'completed':
        statusColor = AppTheme.primaryColor;
        statusText = 'مكتمل';
        break;
      case 'deposit_refunded':
        statusColor = AppTheme.borderColor;
        statusText = 'تم استرداد العربون';
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = status;
    }

    // Format date
    String dateStr = '';
    if (booking['startDate'] != null) {
      dateStr = DateParsing.display(booking['startDate'],
          fallback: booking['startDate'].toString());
    } else if (booking['requestDate'] != null) {
      dateStr =
          DateParsing.display(booking['requestDate'], fallback: 'اليوم');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        booking['image'] ?? 'assets/images/home1.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.backgroundColor,
                            child: const Icon(Icons.home,
                                color: AppTheme.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['title'] ??
                                booking['service'] ??
                                'طلب خدمة',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (booking['duration'] != null)
                            Text('المدة: ${booking['duration']}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${booking['price']} ج.م',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold)),
                          if (booking['depositAmount'] != null ||
                              booking['remainingAmount'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                                'عربون: ${booking['depositAmount'] ?? '0'} ج.م • متبقي: ${booking['remainingAmount'] ?? '0'} ج.م',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                if (status == 'approved') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final allowed = await AuthGate.requireLogin(
                          context,
                          actionLabel: 'دفع الحجز وإصدار العقد',
                        );
                        if (!allowed || !mounted) return;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              itemType: 'booking',
                              itemData: booking,
                              amount: double.tryParse(
                                      booking['price'].toString()) ??
                                  0.0,
                            ),
                          ),
                        );

                        if (result == true) {
                          _loadBookings();
                        }
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('ادفع الآن واصدر العقد'),
                    ),
                  ),
                ],

                if (status == 'viewing_scheduled' ||
                    status == 'deposit_paid') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final allowed = await AuthGate.requireLogin(
                              context,
                              actionLabel: 'استكمال الدفعة النهائية',
                            );
                            if (!allowed || !mounted) return;
                            final total = double.tryParse(
                                    booking['price']?.toString() ?? '0') ??
                                0.0;
                            final deposit = double.tryParse(
                                    booking['depositAmount']?.toString() ??
                                        (total * 0.10).toString()) ??
                                (total * 0.10);
                            final remaining = double.tryParse(
                                    booking['remainingAmount']?.toString() ??
                                        (total - deposit).toString()) ??
                                (total - deposit);

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  itemType: 'booking',
                                  itemData: booking,
                                  amount: remaining,
                                  paymentStage: 'remaining',
                                  totalAmount: total,
                                  depositAmount: deposit,
                                  remainingAmount: remaining,
                                ),
                              ),
                            );

                            if (result == true) {
                              _loadBookings();
                            }
                          },
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('استكمال الصفقة'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final total = double.tryParse(
                                    booking['price']?.toString() ?? '0') ??
                                0.0;
                            final deposit = double.tryParse(
                                    booking['depositAmount']?.toString() ??
                                        (total * 0.10).toString()) ??
                                (total * 0.10);
                            await WalletService.refundBookingDeposit(
                              title:
                                  'استرداد عربون ${booking['title'] ?? 'الحجز'}',
                              amount: deposit,
                              bookingId: booking['id'].toString(),
                            );
                            await DataService.refundBookingDeposit(
                                booking['id'].toString());
                            _loadBookings();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'تم طلب استرداد عربون بقيمة ${deposit.toStringAsFixed(0)} ج.م'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.keyboard_return_rounded,
                              size: 18),
                          label: const Text('استرداد العربون'),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status == 'paid' ||
                    status == 'active' ||
                    status == 'completed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ContractViewScreen(bookingDetails: booking),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.description_outlined, size: 18),
                          label: const Text('عقدي الإلكتروني'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatDetailsScreen(
                                    userName: 'احمد محمد (المالك)'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('محادثة المالك'),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
