/// Canonical booking lifecycle statuses and valid transitions (demo + API).
class BookingStatus {
  BookingStatus._();

  static const submitted = 'submitted';
  static const pending = 'pending';
  static const corporatePending = 'corporate_pending';
  static const depositPaid = 'deposit_paid';
  static const viewingScheduled = 'viewing_scheduled';
  static const confirmed = 'confirmed';
  static const approved = 'approved';
  static const paid = 'paid';
  static const active = 'active';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const rejected = 'rejected';
  static const depositRefunded = 'deposit_refunded';
  static const disputed = 'disputed';

  static const terminal = {
    completed,
    cancelled,
    rejected,
    depositRefunded,
  };

  static const Map<String, Set<String>> transitions = {
    submitted: {depositPaid, viewingScheduled, approved, cancelled, rejected, corporatePending},
    pending: {depositPaid, viewingScheduled, approved, cancelled, rejected, corporatePending},
    corporatePending: {approved, rejected, cancelled, depositPaid},
    depositPaid: {approved, confirmed, cancelled, depositRefunded, disputed, viewingScheduled},
    viewingScheduled: {approved, confirmed, cancelled, depositRefunded, disputed},
    approved: {paid, confirmed, active, cancelled, disputed},
    confirmed: {paid, active, completed, cancelled, disputed},
    paid: {active, completed, disputed},
    active: {completed, cancelled, disputed},
    disputed: {cancelled, completed, active, depositRefunded},
  };

  static String normalize(String? raw) {
    final s = (raw ?? submitted).trim().toLowerCase();
    switch (s) {
      case 'معلق':
        return pending;
      case 'موعد معاينة':
        return viewingScheduled;
      case 'مؤكد':
        return approved;
      case 'مؤكد نهائي':
        return confirmed;
      case 'مدفوع':
        return paid;
      case 'عربون':
        return depositPaid;
      case 'مكتمل':
        return completed;
      case 'ملغي':
        return cancelled;
      case 'مسترد':
        return depositRefunded;
      case 'مرفوض':
        return rejected;
      case 'نشط':
        return active;
      case 'متنازع':
        return disputed;
      default:
        return s;
    }
  }

  static bool canTransition(String from, String to) {
    final f = normalize(from);
    final t = normalize(to);
    if (f == t) return true;
    if (terminal.contains(f)) return false;
    return transitions[f]?.contains(t) ?? false;
  }

  static String arabicLabel(String? status) {
    switch (normalize(status)) {
      case submitted:
        return 'مُرسَل';
      case pending:
        return 'قيد الانتظار';
      case corporatePending:
        return 'حجز جماعي — مراجعة';
      case depositPaid:
        return 'عربون مدفوع';
      case viewingScheduled:
        return 'عربون المعاينة';
      case approved:
        return 'موافقة المالك';
      case confirmed:
        return 'مؤكد';
      case paid:
        return 'مدفوع بالكامل';
      case active:
        return 'نشط';
      case completed:
        return 'مكتمل';
      case cancelled:
        return 'ملغي';
      case rejected:
        return 'مرفوض';
      case depositRefunded:
        return 'تم استرداد العربون';
      case disputed:
        return 'قيد النزاع';
      default:
        return status ?? 'غير معروف';
    }
  }

  static List<Map<String, dynamic>> defaultTimeline(String currentStatus) {
    final current = normalize(currentStatus);
    final steps = <Map<String, dynamic>>[
      {'status': submitted, 'label': 'إرسال الطلب', 'icon': 'send'},
      {'status': depositPaid, 'label': 'دفع العربون', 'icon': 'payments'},
      {'status': approved, 'label': 'موافقة المالك', 'icon': 'verified'},
      {'status': paid, 'label': 'إتمام الدفع', 'icon': 'account_balance'},
      {'status': active, 'label': 'بداية الإيجار', 'icon': 'home'},
      {'status': completed, 'label': 'انتهاء العقد', 'icon': 'done_all'},
    ];

    if (current == rejected) {
      return [
        {'status': submitted, 'label': 'إرسال الطلب', 'done': true},
        {'status': rejected, 'label': 'مرفوض', 'done': true, 'failed': true},
      ];
    }
    if (current == cancelled) {
      return [
        {'status': submitted, 'label': 'إرسال الطلب', 'done': true},
        {'status': cancelled, 'label': 'ملغي', 'done': true, 'failed': true},
      ];
    }
    if (current == depositRefunded) {
      return [
        {'status': submitted, 'label': 'إرسال الطلب', 'done': true},
        {'status': depositPaid, 'label': 'دفع العربون', 'done': true},
        {'status': depositRefunded, 'label': 'استرداد العربون', 'done': true},
      ];
    }
    if (current == disputed) {
      return [
        {'status': submitted, 'label': 'إرسال الطلب', 'done': true},
        {'status': depositPaid, 'label': 'دفع العربون', 'done': true},
        {'status': disputed, 'label': 'نزاع — مراجعة إدارية', 'done': true, 'failed': true},
      ];
    }

    const order = [
      submitted,
      pending,
      corporatePending,
      depositPaid,
      viewingScheduled,
      approved,
      confirmed,
      paid,
      active,
      completed,
    ];
    final currentIdx = order.indexOf(current);
    return steps.map((step) {
      final stepStatus = step['status'] as String;
      final stepIdx = order.indexOf(stepStatus);
      final done = currentIdx >= 0 && stepIdx >= 0 && stepIdx <= currentIdx;
      final active = stepStatus == current ||
          (current == pending && stepStatus == submitted) ||
          (current == viewingScheduled && stepStatus == depositPaid) ||
          (current == confirmed && stepStatus == paid);
      return {
        ...step,
        'done': done || active,
        'active': active,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> buildTimeline(
    Map<String, dynamic> booking,
  ) {
    final history = booking['statusHistory'];
    if (history is List && history.isNotEmpty) {
      return history
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return defaultTimeline(booking['status']?.toString() ?? submitted);
  }
}
