import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';

/// Share Ejari invite link with Arabic copy.
class ShareAppService {
  ShareAppService._();

  static const String _shareMessageAr =
      'جرّب تطبيق إيجاري — منصة إيجار وبيع عقارات في مصر. '
      'حجز، عقود، محفظة، وصيانة في مكان واحد.\n\n';

  static Future<void> shareInvite() async {
    await Share.share(
      '$_shareMessageAr${AppConfig.inviteUrl}',
      subject: 'تطبيق إيجاري',
    );
  }
}
