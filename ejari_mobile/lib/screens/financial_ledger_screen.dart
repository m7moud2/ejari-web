import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinancialLedgerScreen extends StatefulWidget {
  final String role; // 'admin', 'tenant', 'owner', 'tech'
  const FinancialLedgerScreen({super.key, required this.role});

  @override
  State<FinancialLedgerScreen> createState() => _FinancialLedgerScreenState();
}

class _FinancialLedgerScreenState extends State<FinancialLedgerScreen> {
  // Mock Data mimicking a strict Ledger Database
  // In a ledger, balances are derived, not set directly.
  final List<Map<String, dynamic>> _ledgerTransactions = [
    {
      'ref': 'TRX-1001',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'Rent Payment',
      'amount': 8500.0,
      'from': 'محفظة المستأجر (TEN-101)',
      'to': 'محفظة إيجاري (Escrow)',
      'status': 'Completed',
      'receiptId': 'REC-9954',
      'notes': 'دفع قسط إيجار شهر نوفمبر',
    },
    {
      'ref': 'TRX-1002',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'Rent Settlement',
      'amount': 8075.0, // After 5% platform fee
      'from': 'محفظة إيجاري (Escrow)',
      'to': 'محفظة المالك (OWN-55)',
      'status': 'Completed',
      'receiptId': 'REC-9955',
      'notes': 'تحويل صافي الإيجار للمالك',
    },
    {
      'ref': 'TRX-1003',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'Platform Fee',
      'amount': 425.0,
      'from': 'محفظة إيجاري (Escrow)',
      'to': 'محفظة أرباح المنصة',
      'status': 'Completed',
      'receiptId': 'REC-9956',
      'notes': 'عمولة المنصة 5% عن قسط إيجار',
    },
    {
      'ref': 'TRX-1004',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'Maintenance Payment',
      'amount': 250.0,
      'from': 'محفظة المستأجر (TEN-101)',
      'to': 'محفظة إيجاري (Escrow)',
      'status': 'Escrow', // Waiting for tech completion
      'receiptId': 'REC-9957',
      'notes': 'مبلغ صيانة محتجز لحين إنهاء المهمة',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.role == 'admin'
            ? 'الدفتر المالي العام (Ledger)'
            : 'سجل العمليات المالية'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.role == 'admin') _buildAdminWarning(),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ledgerTransactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionRow(_ledgerTransactions[index]);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: Colors.blueGrey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'أنت في وضع الرقابة (Admin). لا يمكن تعديل الأرصدة مباشرة. جميع العمليات هنا هي Atomic Transactions لا تقبل التعديل.',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> trx) {
    bool isEscrow = trx['status'] == 'Escrow';
    bool isPlatform = trx['type'] == 'Platform Fee';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isEscrow
                ? Colors.orange.withOpacity(0.5)
                : AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trx['ref'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEscrow
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEscrow ? 'في الضمان (Escrow)' : 'مكتمل (Completed)',
                  style: TextStyle(
                    color: isEscrow ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(isPlatform ? Icons.account_balance : Icons.swap_horiz,
                  color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trx['type'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(trx['notes'],
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text('${trx['amount']} ج.م',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color:
                          isPlatform ? Colors.purple : AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('من',
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(trx['from'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إلى',
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(trx['to'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
