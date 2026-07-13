/// معاينة عقار — حالة الموعد وانتقالاته الآمنة.
class ViewingStatus {
  ViewingStatus._();

  static const requested = 'requested';
  static const confirmed = 'confirmed';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
  static const rejected = 'rejected';
  static const noShow = 'no_show';
  static const rescheduled = 'rescheduled';

  static const terminal = {
    completed,
    cancelled,
    rejected,
    noShow,
  };

  static const Map<String, Set<String>> transitions = {
    requested: {confirmed, rejected, cancelled, rescheduled},
    rescheduled: {confirmed, rejected, cancelled, rescheduled},
    confirmed: {completed, cancelled, noShow, rescheduled},
    completed: {},
    cancelled: {},
    rejected: {},
    noShow: {},
  };

  static String normalize(String? raw) {
    final s = (raw ?? requested).trim().toLowerCase();
    switch (s) {
      case 'pending':
      case 'معلق':
      case 'مطلوب':
        return requested;
      case 'approved':
      case 'مؤكد':
        return confirmed;
      case 'done':
      case 'مكتمل':
        return completed;
      case 'ملغي':
        return cancelled;
      case 'مرفوض':
        return rejected;
      case 'no-show':
      case 'غياب':
        return noShow;
      case 'إعادة جدولة':
        return rescheduled;
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
      case requested:
        return 'بانتظار موافقة المالك';
      case confirmed:
        return 'موعد مؤكد';
      case completed:
        return 'تمت المعاينة';
      case cancelled:
        return 'ملغي';
      case rejected:
        return 'مرفوض';
      case noShow:
        return 'لم يحضر';
      case rescheduled:
        return 'إعادة جدولة';
      default:
        return status ?? 'غير معروف';
    }
  }
}

/// موعد معاينة عقار (للإيجار فقط).
class ViewingAppointment {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String? propertyImage;
  final String tenantEmail;
  final String tenantName;
  final String ownerEmail;
  final DateTime scheduledAt;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? rejectedAt;
  final String? note;
  final String? ownerNote;
  final String? bookingId;
  final bool tenantAttended;
  final bool ownerMarkedComplete;

  const ViewingAppointment({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyImage,
    required this.tenantEmail,
    required this.tenantName,
    required this.ownerEmail,
    required this.scheduledAt,
    this.status = ViewingStatus.requested,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.rejectedAt,
    this.note,
    this.ownerNote,
    this.bookingId,
    this.tenantAttended = false,
    this.ownerMarkedComplete = false,
  });

  ViewingAppointment copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    String? tenantEmail,
    String? tenantName,
    String? ownerEmail,
    DateTime? scheduledAt,
    String? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? rejectedAt,
    String? note,
    String? ownerNote,
    String? bookingId,
    bool? tenantAttended,
    bool? ownerMarkedComplete,
  }) {
    return ViewingAppointment(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      tenantEmail: tenantEmail ?? this.tenantEmail,
      tenantName: tenantName ?? this.tenantName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      note: note ?? this.note,
      ownerNote: ownerNote ?? this.ownerNote,
      bookingId: bookingId ?? this.bookingId,
      tenantAttended: tenantAttended ?? this.tenantAttended,
      ownerMarkedComplete: ownerMarkedComplete ?? this.ownerMarkedComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        if (propertyImage != null) 'propertyImage': propertyImage,
        'tenantEmail': tenantEmail,
        'tenantName': tenantName,
        'ownerEmail': ownerEmail,
        'scheduledAt': scheduledAt.toIso8601String(),
        'status': ViewingStatus.normalize(status),
        'createdAt': createdAt.toIso8601String(),
        if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
        if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
        if (note != null) 'note': note,
        if (ownerNote != null) 'ownerNote': ownerNote,
        if (bookingId != null) 'bookingId': bookingId,
        'tenantAttended': tenantAttended,
        'ownerMarkedComplete': ownerMarkedComplete,
      };

  factory ViewingAppointment.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    }

    return ViewingAppointment(
      id: json['id']?.toString() ?? '',
      propertyId: json['propertyId']?.toString() ?? '',
      propertyTitle: json['propertyTitle']?.toString() ?? 'عقار',
      propertyImage: json['propertyImage']?.toString() ??
          json['image']?.toString(),
      tenantEmail: json['tenantEmail']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? 'مستأجر',
      ownerEmail: json['ownerEmail']?.toString() ??
          json['ownerId']?.toString() ??
          '',
      scheduledAt: parse(json['scheduledAt']) ?? DateTime.now(),
      status: ViewingStatus.normalize(json['status']?.toString()),
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      confirmedAt: parse(json['confirmedAt']),
      completedAt: parse(json['completedAt']),
      cancelledAt: parse(json['cancelledAt']),
      rejectedAt: parse(json['rejectedAt']),
      note: json['note']?.toString(),
      ownerNote: json['ownerNote']?.toString(),
      bookingId: json['bookingId']?.toString(),
      tenantAttended: json['tenantAttended'] == true,
      ownerMarkedComplete: json['ownerMarkedComplete'] == true,
    );
  }

  String get statusLabel => ViewingStatus.arabicLabel(status);

  bool get isActive => !ViewingStatus.terminal.contains(
        ViewingStatus.normalize(status),
      );
}
