// Canonical booking lifecycle statuses and valid transitions (demo + API).
import '../utils/date_utils.dart';

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
        return 'موعد معاينة';
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

  /// Compact 6-step timeline (legacy / list cards).
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
      final stepStatus = step['status']?.toString() ?? '';
      final stepIdx = order.indexOf(stepStatus);
      final done = currentIdx >= 0 && stepIdx >= 0 && stepIdx <= currentIdx;
      final isActive = stepStatus == current ||
          (current == pending && stepStatus == submitted) ||
          (current == viewingScheduled && stepStatus == depositPaid) ||
          (current == confirmed && stepStatus == paid);
      return {
        ...step,
        'done': done || isActive,
        'active': isActive,
      };
    }).toList();
  }

  /// Full 10-step tenant tracking timeline for BookingTrackScreen.
  static List<Map<String, dynamic>> detailedTrackTimeline(
    Map<String, dynamic> booking,
  ) {
    final current = normalize(booking['status']?.toString());
    final checkedIn = booking['checkedInAt'] != null;
    final checkedOut = booking['checkedOutAt'] != null;
    final dateMap = DateParsing.timelineDatesForBooking(booking);

    String? atFor(String id) {
      final v = dateMap[id];
      if (v == null || v.isEmpty || v == '—') return null;
      return v;
    }

    if (current == rejected) {
      return [
        {
          'id': 'submitted',
          'label': 'طلب مُرسل',
          'done': true,
          if (atFor('submitted') != null) 'at': atFor('submitted'),
        },
        {
          'id': 'rejected',
          'label': 'مرفوض',
          'done': true,
          'failed': true,
          'active': true,
          if (atFor('rejected') != null) 'at': atFor('rejected'),
        },
      ];
    }
    if (current == cancelled) {
      return [
        {
          'id': 'submitted',
          'label': 'طلب مُرسل',
          'done': true,
          if (atFor('submitted') != null) 'at': atFor('submitted'),
        },
        {
          'id': 'cancelled',
          'label': 'ملغي',
          'done': true,
          'failed': true,
          'active': true,
          if (atFor('cancelled') != null) 'at': atFor('cancelled'),
        },
      ];
    }
    if (current == depositRefunded) {
      return [
        {
          'id': 'submitted',
          'label': 'طلب مُرسل',
          'done': true,
          if (atFor('submitted') != null) 'at': atFor('submitted'),
        },
        {
          'id': 'deposit',
          'label': 'دفع العربون / المقدم',
          'done': true,
          if (atFor('deposit') != null) 'at': atFor('deposit'),
        },
        {
          'id': 'refund',
          'label': 'استرداد التأمين / تقييم',
          'done': true,
          'active': true,
          if (atFor('refund') != null) 'at': atFor('refund'),
        },
      ];
    }
    if (current == disputed) {
      return [
        {
          'id': 'submitted',
          'label': 'طلب مُرسل',
          'done': true,
          if (atFor('submitted') != null) 'at': atFor('submitted'),
        },
        {
          'id': 'deposit',
          'label': 'دفع العربون / المقدم',
          'done': true,
          if (atFor('deposit') != null) 'at': atFor('deposit'),
        },
        {
          'id': 'disputed',
          'label': 'نزاع — مراجعة إدارية',
          'done': true,
          'failed': true,
          'active': true,
          if (atFor('disputed') != null) 'at': atFor('disputed'),
        },
      ];
    }

    // Index of the current step (0..9). Steps before it are done.
    int progress;
    if (current == completed) {
      progress = 9;
    } else if (checkedOut) {
      progress = 9;
    } else if (checkedIn) {
      progress = 7; // الإقامة جارية
    } else if (current == active) {
      progress = 6; // تسجيل الدخول
    } else if (current == paid || current == confirmed) {
      progress = 5; // QR جاهز
    } else if (current == approved) {
      progress = 3; // إكمال الدفع
    } else if (current == viewingScheduled) {
      progress = 2; // موافقة المالك / معاينة
    } else if (current == depositPaid) {
      progress = 2; // موافقة المالك
    } else {
      progress = 0; // طلب مُرسل
    }

    final labels = <String>[
      'طلب مُرسل',
      'دفع العربون / المقدم',
      current == viewingScheduled ? 'موعد المعاينة / موافقة المالك' : 'موافقة المالك',
      'إكمال الدفع',
      'العقد جاهز',
      'QR جاهز للدخول',
      'تسجيل الدخول (Check-in)',
      'الإقامة جارية',
      'تسجيل الخروج (Check-out)',
      'استرداد التأمين / تقييم',
    ];
    final ids = <String>[
      'submitted',
      'deposit',
      'owner_approval',
      'full_payment',
      'contract',
      'qr',
      'check_in',
      'stay',
      'check_out',
      'refund_rate',
    ];

    final allDone = current == completed;
    return List.generate(labels.length, (i) {
      final done = allDone || i < progress;
      final isCurrent = !allDone && i == progress;
      final at = atFor(ids[i]);
      return {
        'id': ids[i],
        'label': labels[i],
        'done': done,
        'active': isCurrent,
        if (at != null && (done || isCurrent)) 'at': at,
      };
    });
  }

  static List<Map<String, dynamic>> buildTimeline(
    Map<String, dynamic> booking, {
    bool detailed = false,
  }) {
    if (detailed) {
      return detailedTrackTimeline(booking);
    }
    final history = booking['statusHistory'];
    if (history is List && history.isNotEmpty) {
      return history
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return defaultTimeline(booking['status']?.toString() ?? submitted);
  }

  /// Next tenant action: (icon, Arabic label, actionKey).
  static (String icon, String label, String key)? nextActionForBooking(
    Map<String, dynamic> booking,
  ) {
    final status = normalize(booking['status']?.toString());
    final paymentRaw = booking['paymentStatus']?.toString() ?? '';
    final depositAlreadyPaid = booking['depositPaid'] == true ||
        paymentRaw == 'deposit_paid' ||
        paymentRaw == 'pre_entry_paid' ||
        paymentRaw == 'paid';
    switch (status) {
      case submitted:
      case pending:
      case corporatePending:
        if (!depositAlreadyPaid) {
          return ('payments', 'ادفع العربون', 'pay_deposit');
        }
        return ('hourglass', 'انتظر موافقة المالك', 'wait');
      case approved:
        return ('payments', 'ادفع الآن', 'pay');
      case depositPaid:
        return ('hourglass', 'انتظر موافقة المالك', 'wait');
      case viewingScheduled:
        return ('event', 'موعد المعاينة مجدول', 'viewing');
      case paid:
      case confirmed:
      case active:
        if (booking['checkedInAt'] == null) {
          return ('qr', 'اعرض QR للاستلام', 'qr_checkin');
        }
        if (booking['checkedOutAt'] == null) {
          return ('logout', 'سجّل خروج', 'checkout');
        }
        return ('star', 'قيّم', 'rate');
      case completed:
        return ('star', 'قيّم', 'rate');
      default:
        return null;
    }
  }
}
