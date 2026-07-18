/// Public contact + social destinations for the app.
class SocialLinks {
  static const String facebook =
      'https://www.facebook.com/people/إيجاري-EjariApp/61591649755623/';
  static const String linkedin =
      'https://www.linkedin.com/company/%E2%80%8Eإيجاري-ejariapp/?viewAsMember=true';

  /// Support inbox (also used in About / Help / Terms).
  static const String supportEmail = 'support@ejari.app';

  /// Egypt WhatsApp support number (digits only, country code included).
  static const String supportWhatsAppE164 = '201280083336';

  static String get whatsappUrl => 'https://wa.me/$supportWhatsAppE164';

  static String get mailtoSupport => 'mailto:$supportEmail';
}
