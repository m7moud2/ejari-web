/// Arabic labels for wallet transaction categories.
class WalletCategoryLabels {
  WalletCategoryLabels._();

  static const Map<String, String> _labels = {
    'rent': 'إيجار',
    'booking_deposit': 'عربون',
    'deposit': 'عربون',
    'refund': 'استرداد',
    'maintenance': 'صيانة',
    'platform': 'عمولة منصة',
    'withdrawal': 'سحب',
    'topup': 'شحن',
    'escrow': 'إسكرو',
    'income': 'دخل',
    'commission': 'عمولة',
  };

  static String labelFor(Map<String, dynamic> tx) {
    final category = tx['category']?.toString() ?? '';
    if (category.isNotEmpty && _labels.containsKey(category)) {
      return _labels[category]!;
    }
    final type = tx['type']?.toString() ?? '';
    if (type == 'refund') return 'استرداد';
    if (type == 'escrow') return 'عربون';
    if (type == 'income') return 'دخل';
    return 'عملية';
  }

  static bool matchesFilter(Map<String, dynamic> tx, String filter) {
    if (filter == 'الكل') return true;
    final category = tx['category']?.toString() ?? '';
    final type = tx['type']?.toString() ?? '';
    switch (filter) {
      case 'إيجار':
        return category == 'rent';
      case 'عربون':
        return category == 'booking_deposit' ||
            category == 'deposit' ||
            type == 'escrow';
      case 'استرداد':
        return category == 'refund' || type == 'refund';
      case 'شحن':
        return category == 'topup' ||
            (type == 'income' && category == 'topup') ||
            (tx['title']?.toString().contains('شحن') ?? false);
      case 'إيداع':
        return tx['type'] == 'credit' ||
            type == 'income' ||
            type == 'refund' ||
            category == 'topup';
      case 'سحب':
        return tx['type'] == 'expense' ||
            type == 'withdrawal' ||
            category == 'withdrawal';
      default:
        return true;
    }
  }
}
