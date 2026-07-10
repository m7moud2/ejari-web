/// نوع المستأجر في مسار الحجز.
enum TenantType {
  individual,
  family,
  multiplePersons,
}

extension TenantTypeX on TenantType {
  String get arabicLabel {
    switch (this) {
      case TenantType.individual:
        return 'فرد';
      case TenantType.family:
        return 'أسرة';
      case TenantType.multiplePersons:
        return 'أكثر من فرد';
    }
  }

  String get value {
    switch (this) {
      case TenantType.individual:
        return 'individual';
      case TenantType.family:
        return 'family';
      case TenantType.multiplePersons:
        return 'multiple_persons';
    }
  }

}

TenantType tenantTypeFromValue(String? raw) {
  switch (raw) {
    case 'family':
      return TenantType.family;
    case 'multiple_persons':
      return TenantType.multiplePersons;
    default:
      return TenantType.individual;
  }
}
