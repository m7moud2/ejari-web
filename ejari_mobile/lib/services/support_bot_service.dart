import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_service.dart';
import 'data_service.dart';
import 'support_service.dart';

/// Automated support bot with shortcut replies and escalation to live agent.
class SupportBotService {
  static const String botSenderId = 'support_bot';
  static const int _escalationThreshold = 3;

  static const String welcomeMessage =
      'أهلاً بك في دعم إيجاري 👋\n'
      'أنا مساعدك الذكي. اختر الموضوع الأقرب لمشكلتك وسأحاول مساعدتك فوراً.\n'
      'إذا لم تجد الحل، يمكنك التحدث مع موظف خدمة العملاء في أي وقت.';

  static const List<SupportShortcut> shortcuts = [
    SupportShortcut(
      id: 'payment',
      emoji: '💰',
      label: 'مشكلة في الدفع',
      response:
          '💰 **مشاكل الدفع والمحفظة**\n\n'
          '• طرق الدفع المتاحة: بطاقة بنكية، محفظة إيجاري، تحويل بنكي موثّق.\n'
          '• إيصال الدفع يصلك فوراً في: **حجوزاتي ← تفاصيل الحجز ← الإيصال**.\n'
          '• إذا فشل الدفع: تأكد من رصيد البطاقة، ثم أعد المحاولة من نفس صفحة الحجز.\n'
          '• رصيد المحفظة: **الملف الشخصي ← المحفظة**.\n\n'
          'هل المشكلة مستمرة بعد إعادة المحاولة؟',
    ),
    SupportShortcut(
      id: 'booking',
      emoji: '📅',
      label: 'مشكلة في الحجز',
      response:
          '📅 **الحجوزات والإلغاء**\n\n'
          '• تتبّع حالة حجزك من: **حجوزاتي** (مؤكد / قيد المراجعة / ملغي).\n'
          '• الإلغاء المجاني: خلال **48 ساعة** من تاريخ الحجز (حسب سياسة العقار).\n'
          '• بعد 48 ساعة: قد تُطبَّق رسوم إلغاء حسب شروط العقار.\n'
          '• استرداد المبلغ: يُعاد لمحفظتك أو بطاقتك خلال **3–7 أيام عمل**.\n\n'
          'هل تحتاج مساعدة في حجز محدد؟ اذكر رقم الحجز إن وُجد.',
    ),
    SupportShortcut(
      id: 'property',
      emoji: '🏠',
      label: 'مشكلة في العقار',
      response:
          '🏠 **مشاكل العقار أثناء الإقامة**\n\n'
          '• للإبلاغ عن مشكلة: **طلب صيانة** من القائمة أو من تفاصيل الحجز.\n'
          '• أرفق صوراً واضحة للمشكلة لتسريع المعالجة.\n'
          '• للتواصل مع المالك: استخدم **الشات** من صفحة العقار (بعد تأكيد الحجز).\n'
          '• للحالات العاجلة: اختر **تحدث مع خدمة العملاء** أدناه.\n\n'
          'ننصح بتوثيق المشكلة بالصور فور ملاحظتها.',
    ),
    SupportShortcut(
      id: 'kyc',
      emoji: '🔐',
      label: 'توثيق الحساب',
      response:
          '🔐 **توثيق الحساب (KYC)**\n\n'
          '• ابدأ من: **الملف الشخصي ← توثيق الحساب**.\n'
          '• المطلوب: صورة الهوية/الإقامة + صورة شخصية (سيلفي).\n'
          '• استخدم الكاميرا داخل التطبيق لالتقاط الصور بوضوح.\n'
          '• مدة المراجعة: عادةً **24–48 ساعة** في أيام العمل.\n'
          '• ستصلك إشعار عند القبول أو إذا طُلب تعديل.\n\n'
          'هل واجهت مشكلة في رفع الصور؟',
    ),
    SupportShortcut(
      id: 'subscription',
      emoji: '💳',
      label: 'الاشتراك والباقات',
      response:
          '💳 **الاشتراكات والباقات**\n\n'
          '• باقات الملاك: **الملف الشخصي ← باقات الإعلان**.\n'
          '• الترقية: اختر الباقة الأعلى وادفع الفرق — تُفعَّل فوراً.\n'
          '• باقة المستأجر: مزايا إضافية في **الاشتراكات**.\n'
          '• الفواتير والتجديد: تظهر في سجل المدفوعات.\n\n'
          'هل تريد معرفة الفرق بين الباقات؟',
    ),
    SupportShortcut(
      id: 'maintenance',
      emoji: '🔧',
      label: 'طلب صيانة',
      response:
          '🔧 **طلبات الصيانة**\n\n'
          '• أنشئ طلباً من: **الصيانة ← طلب جديد**.\n'
          '• حدّد نوع المشكلة (سباكة، كهرباء، تكييف، إلخ).\n'
          '• يمكنك متابعة الحالة: قيد الانتظار ← قيد التنفيذ ← مكتمل.\n'
          '• الفني يتواصل معك عبر التطبيق عند قبول الطلب.\n\n'
          'افتح قسم الصيانة من القائمة الرئيسية لبدء طلبك الآن.',
      actionRoute: 'maintenance',
    ),
    SupportShortcut(
      id: 'contracts',
      emoji: '📄',
      label: 'العقود والإيصالات',
      response:
          '📄 **العقود والإيصالات**\n\n'
          '• العقود: **عقودي** — نسخة PDF موقعة إلكترونياً.\n'
          '• الإيصالات: **حجوزاتي ← تفاصيل الحجز ← عرض الإيصال**.\n'
          '• كشف الإيجار: متاح للعقود طويلة المدى من **عقودي**.\n'
          '• يمكنك مشاركة أو تحميل أي مستند من داخل التطبيق.\n\n'
          'هل تبحث عن عقد أو إيصال لحجز معيّن؟',
      actionRoute: 'contracts',
    ),
    SupportShortcut(
      id: 'other',
      emoji: '❓',
      label: 'سؤال آخر',
      response:
          '❓ **سؤال آخر**\n\n'
          'اكتب سؤالك بالتفصيل في مربع الرسائل أدناه.\n'
          'سأحاول مطابقته مع الحلول المناسبة، وإذا لم أجد إجابة كافية '
          'سأعرض عليك التحدث مع موظف خدمة العملاء.',
    ),
    SupportShortcut(
      id: 'escalate',
      emoji: '👤',
      label: 'تحدث مع خدمة العملاء',
      response: '',
      isEscalation: true,
    ),
  ];

  static SupportShortcut? shortcutById(String id) {
    try {
      return shortcuts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static String _stateKey(String chatId) => 'support_bot_state_$chatId';

  static Future<Map<String, dynamic>> getState(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey(chatId));
    if (raw == null) {
      return {
        'mode': 'bot',
        'unresolvedCount': 0,
        'awaitingFeedback': false,
        'initialized': false,
        'lastShortcutId': null,
      };
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> _saveState(
      String chatId, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey(chatId), jsonEncode(state));
  }

  static Future<bool> isEscalated(String chatId) async {
    final state = await getState(chatId);
    return state['mode'] == 'escalated';
  }

  /// Initialize a new support chat with welcome message and shortcuts marker.
  static Future<void> initializeChat(String chatId) async {
    final state = await getState(chatId);
    if (state['initialized'] == true) return;

    await ChatService.sendBotMessage(
      chatId,
      welcomeMessage,
      showShortcuts: true,
    );

    state['initialized'] = true;
    state['mode'] = 'bot';
    await _saveState(chatId, state);
  }

  /// Handle shortcut tap — returns bot reply metadata for UI.
  static Future<SupportBotAction> handleShortcut({
    required String chatId,
    required String shortcutId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final shortcut = shortcutById(shortcutId);
    if (shortcut == null) {
      return const SupportBotAction(
        botText: 'عذراً، لم أتعرف على هذا الخيار. اختر من القائمة أدناه.',
        showShortcuts: true,
      );
    }

    if (shortcut.isEscalation) {
      return escalateToLiveAgent(
        chatId: chatId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        reason: 'طلب المستخدم التحدث مع خدمة العملاء',
      );
    }

    final state = await getState(chatId);
    if (state['mode'] == 'escalated') {
      return const SupportBotAction(showShortcuts: false, escalated: true);
    }

    await ChatService.sendMessage(
      chatId,
      userId,
      '${shortcut.emoji} ${shortcut.label}',
      isShortcut: true,
      shortcutId: shortcutId,
    );

    if (shortcut.id == 'other') {
      state['awaitingFreeText'] = true;
      await _saveState(chatId, state);
      await ChatService.sendBotMessage(chatId, shortcut.response);
      return SupportBotAction(
        botText: shortcut.response,
        showShortcuts: false,
        awaitingFreeText: true,
      );
    }

    state['lastShortcutId'] = shortcutId;
    state['awaitingFeedback'] = true;
    await _saveState(chatId, state);

    await ChatService.sendBotMessage(
      chatId,
      shortcut.response,
      showFeedback: true,
      actionRoute: shortcut.actionRoute,
    );

    return SupportBotAction(
      botText: shortcut.response,
      showFeedback: true,
      actionRoute: shortcut.actionRoute,
    );
  }

  /// Handle free-text user message in bot mode.
  static Future<SupportBotAction?> handleFreeText({
    required String chatId,
    required String text,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final state = await getState(chatId);
    if (state['mode'] == 'escalated') return null;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    await ChatService.sendMessage(chatId, userId, trimmed);

    final keywordMatch = _matchKeywords(trimmed);
    String botReply;
    if (keywordMatch != null) {
      botReply = keywordMatch.response;
      state['lastShortcutId'] = keywordMatch.id;
    } else {
      botReply =
          'شكراً لتوضيحك. لم أجد إجابة دقيقة لسؤالك، لكن يمكنني مساعدتك عبر '
          'الخيارات أدناه.\n\n'
          'إذا استمرت المشكلة، اضغط **تحدث مع خدمة العملاء** وسيتواصل معك موظف.';
      state['unresolvedCount'] = (state['unresolvedCount'] as int? ?? 0) + 1;
    }

    state['awaitingFeedback'] = true;
    state['awaitingFreeText'] = false;
    await _saveState(chatId, state);

    await ChatService.sendBotMessage(
      chatId,
      botReply,
      showFeedback: true,
    );

    final unresolved = state['unresolvedCount'] as int? ?? 0;
    return SupportBotAction(
      botText: botReply,
      showFeedback: true,
      suggestEscalation: unresolved >= 2,
      showShortcuts: unresolved >= 2,
    );
  }

  /// Handle "هل ساعدك هذا؟" feedback.
  static Future<SupportBotAction> handleFeedback({
    required String chatId,
    required bool helped,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final state = await getState(chatId);
    if (state['mode'] == 'escalated') {
      return const SupportBotAction(escalated: true);
    }

    state['awaitingFeedback'] = false;
    await ChatService.sendMessage(
      chatId,
      userId,
      helped ? 'نعم، ساعدني' : 'لا، لم يساعدني',
    );

    if (helped) {
      state['unresolvedCount'] = 0;
      await _saveState(chatId, state);
      const thanks =
          'سعداء بخدمتك! 😊\nهل تحتاج مساعدة في شيء آخر؟ اختر من القائمة:';
      await ChatService.sendBotMessage(
        chatId,
        thanks,
        showShortcuts: true,
      );
      return const SupportBotAction(
        botText: thanks,
        showShortcuts: true,
      );
    }

    final count = (state['unresolvedCount'] as int? ?? 0) + 1;
    state['unresolvedCount'] = count;
    await _saveState(chatId, state);

    if (count >= _escalationThreshold) {
      return escalateToLiveAgent(
        chatId: chatId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        reason: 'البوت لم يحل المشكلة بعد $count محاولات',
        botCouldntResolve: true,
      );
    }

    final retry =
        'نأسف أن الحل لم يكن كافياً. جرّب خياراً آخر من القائمة، '
        'أو اكتب تفاصيل أكثر.\n\n'
        '${count >= 2 ? '💡 يمكنك أيضاً التحدث مع موظف خدمة العملاء مباشرة.' : ''}';
    await ChatService.sendBotMessage(
      chatId,
      retry,
      showShortcuts: true,
      suggestEscalation: count >= 2,
    );

    return SupportBotAction(
      botText: retry,
      showShortcuts: true,
      suggestEscalation: count >= 2,
    );
  }

  /// Escalate chat to live admin agent.
  static Future<SupportBotAction> escalateToLiveAgent({
    required String chatId,
    required String userId,
    required String userName,
    required String userEmail,
    required String reason,
    bool botCouldntResolve = true,
  }) async {
    final state = await getState(chatId);
    if (state['mode'] == 'escalated') {
      return const SupportBotAction(escalated: true);
    }

    final history = await ChatService.getMessages(chatId);
    final historySummary = history
        .map((m) {
          final sender = m['senderId']?.toString() ?? '';
          final label = sender == botSenderId
              ? 'البوت'
              : sender == userId
                  ? userName
                  : sender;
          return '$label: ${m['text']}';
        })
        .join('\n');

    final lastShortcut = state['lastShortcutId']?.toString();
    final subject = lastShortcut != null
        ? 'تصعيد: ${shortcutById(lastShortcut)?.label ?? 'دعم فني'}'
        : 'تصعيد إلى موظف خدمة العملاء';

    await SupportService.createTicket(
      userEmail: userEmail,
      userName: userName,
      subject: subject,
      message: reason,
      category: 'support_escalation',
      chatId: chatId,
      botCouldntResolve: botCouldntResolve,
      botHistory: history,
    );

    state['mode'] = 'escalated';
    state['awaitingFeedback'] = false;
    state['awaitingFreeText'] = false;
    await _saveState(chatId, state);
    await ChatService.setSupportMode(chatId, 'live');

    const escalationMsg =
        '✅ **تم تحويلك لموظف خدمة العملاء**\n\n'
        'سيرد عليك أحد ممثلي الدعم في أقرب وقت. '
        'يمكنك متابعة كتابة رسائلك هنا وسيتم إبلاغ الفريق فوراً.\n\n'
        'شكراً لصبرك! 🙏';

    await ChatService.sendBotMessage(chatId, escalationMsg);

    await DataService.addNotificationToUser(
      SupportService.adminEmail,
      'تصعيد دعم — يحتاج موظف 👤',
      '$userName: $reason',
      type: 'support',
      refId: chatId,
      adminFeed: true,
    );

    // Mirror escalation summary for admin chat context.
    if (historySummary.isNotEmpty) {
      await ChatService.sendMessage(
        chatId,
        SupportService.adminEmail,
        '📋 ملخص محادثة البوت:\n$historySummary',
        isSystem: true,
      );
    }

    return const SupportBotAction(
      botText: escalationMsg,
      escalated: true,
      showShortcuts: false,
    );
  }

  static SupportShortcut? _matchKeywords(String input) {
    final lower = input.toLowerCase();

    const keywordMap = {
      'payment': ['دفع', 'دفعة', 'بطاقة', 'محفظة', 'فيزا', 'ماستر', 'تحويل', 'إيصال'],
      'booking': ['حجز', 'احجز', 'إلغاء', 'الغاء', 'استرداد', 'refund', 'حجوزاتي'],
      'property': ['عقار', 'شقة', 'فيلا', 'مشكلة', 'تسريب', 'كهرباء', 'ماء'],
      'kyc': ['توثيق', 'هوية', 'إقامة', 'kyc', 'تحقق', 'صورة'],
      'subscription': ['اشتراك', 'باقة', 'ترقية', 'خطة', 'plan'],
      'maintenance': ['صيانة', 'فني', 'إصلاح', 'تكييف', 'سباكة'],
      'contracts': ['عقد', 'عقود', 'إيصال', 'فاتورة', 'pdf'],
    };

    for (final entry in keywordMap.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          return shortcutById(entry.key);
        }
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> shortcutsForUi() {
    return shortcuts
        .map((s) => {
              'id': s.id,
              'emoji': s.emoji,
              'label': s.label,
              'isEscalation': s.isEscalation,
            })
        .toList();
  }
}

class SupportShortcut {
  final String id;
  final String emoji;
  final String label;
  final String response;
  final bool isEscalation;
  final String? actionRoute;

  const SupportShortcut({
    required this.id,
    required this.emoji,
    required this.label,
    required this.response,
    this.isEscalation = false,
    this.actionRoute,
  });
}

class SupportBotAction {
  final String? botText;
  final bool showShortcuts;
  final bool showFeedback;
  final bool suggestEscalation;
  final bool escalated;
  final bool awaitingFreeText;
  final String? actionRoute;

  const SupportBotAction({
    this.botText,
    this.showShortcuts = false,
    this.showFeedback = false,
    this.suggestEscalation = false,
    this.escalated = false,
    this.awaitingFreeText = false,
    this.actionRoute,
  });
}
