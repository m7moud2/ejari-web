/**
 * Ejari promo — Arabic (default RTL) + English (LTR).
 * Persist: localStorage ejari_promo_lang
 * Override: ?lang=ar | ?lang=en
 */
(function () {
  var STORAGE_KEY = "ejari_promo_lang";

  var STR = {
    ar: {
      "meta.title": "إيجاري — إدارة الإيجار في مصر",
      "meta.desc":
        "إيجاري تطبيق لإدارة الإيجار: عقود، دفع، معاينة، صيانة، ومحفظة — للمستأجر والمالك. الإصدار 1.3.5 لأندرويد.",
      "nav.brand": "إيجاري",
      "nav.trust": "ليه إيجاري",
      "nav.how": "كيف يشتغل",
      "nav.download": "التحميل",
      "nav.contact": "تواصل",
      "nav.home": "الرئيسية",
      "nav.lang": "English",
      "nav.langAria": "التبديل إلى الإنجليزية",
      "num.1": "١",
      "num.2": "٢",
      "num.3": "٣",

      "hero.brandSub": "Ejari",
      "hero.line": "من العقد… لحد الصيانة.",
      "hero.sub":
        "تطبيق مصري لإدارة الإيجار بين المستأجر والمالك — بدون لفّ ولا وعود فاضيّة.",
      "hero.cta": "حمّل التطبيق",
      "hero.secondary": "تعرّف علينا",

      "trust.title": "ليه ناس بتثق في إيجاري",
      "trust.lede":
        "الإيجار في مصر محتاج وضوح أكتر من الكلام. التطبيق بيرتّب العقد والدفع والصيانة في مكان واحد.",
      "trust.1.title": "عقود واضحة",
      "trust.1.body":
        "بنود الإيجار والمدّة والمبلغ قدام الطرفين قبل ما يتأكد الحجز.",
      "trust.2.title": "دفع منظم ومحفظة",
      "trust.2.body":
        "عربون وإيجار واسترداد بتتسجّل في المحفظة بحالة واضحة.",
      "trust.3.title": "صيانة ومتابعة",
      "trust.3.body":
        "طلبات الصيانة مربوطة بالوحدة، والفني يشتغل من نفس التطبيق.",
      "trust.4.title": "أدوار منفصلة",
      "trust.4.body":
        "مستأجر، مالك، فني، وإدارة — كل واحد يشوف اللي يخصّه.",
      "trust.photoAlt": "وحدة سكنية جاهزة للإيجار",

      "how.title": "ثلاث خطوات وبس",
      "how.lede": "من اختيار الوحدة لحد الدخول — المسار واضح.",
      "how.1.title": "اختار الوحدة والمدة",
      "how.1.body": "يومي، أسبوعي، أو شهري — وتشوف التفاصيل قبل ما تحجز.",
      "how.2.title": "ادفع العربون واتفق",
      "how.2.body": "الدفع يتسجّل، والمالك يوافق أو يرد حسب الحالة.",
      "how.3.title": "ادخل بـ QR وتابع الصيانة",
      "how.3.body":
        "رمز دخول عند الوصول، ومتابعة أي طلب صيانة من جوه التطبيق.",

      "mission.body":
        "هدفنا نبسط الإيجار في مصر: أقل سوء تفاهم، وأكتر وضوح بين المستأجر والمالك.",
      "mission.en": "Rental operations for Egypt — plain and practical.",

      "dl.title": "حمّل إيجاري لأندرويد",
      "dl.lede":
        "الإصدار الحالي متاح كملف APK. قريباً على Google Play.",
      "dl.version":
        "أندرويد <strong>1.3.5</strong> · حجم تقريبي حسب جهازك · أندرويد فقط حالياً",
      "dl.apk": "تنزيل APK · 1.3.5",
      "dl.howto": "تعليمات التثبيت",
      "dl.upgrade":
        "لو عندك نسخة قديمة: احذفها الأول، بعدين ثبّت 1.3.5 عشان ما يحصلش تعارض توقيع.",
      "dl.caption":
        "صورة توضيحية — استبدلوها بصور وحداتكم الرسمية لاحقاً.",
      "dl.photoAlt": "شقة سكنية",

      "contact.title": "تواصل معنا",
      "contact.lede": "للدعم والشراكات — ردّنا على واتساب أو الإيميل.",
      "contact.wa": "واتساب · 01280083336",
      "contact.mail": "support@ejari.app",
      "contact.fb": "فيسبوك",
      "contact.li": "لينكدإن",
      "contact.hours": "الدعم عادةً خلال يوم عمل — اكتب رقم الإصدار لو فيه مشكلة تثبيت.",

      "footer.blurb":
        "شركة تطبيق لإدارة الإيجار والعقود في السوق المصري.",
      "footer.legal": "قانوني",
      "footer.privacy": "سياسة الخصوصية",
      "footer.terms": "الشروط والأحكام",
      "footer.links": "روابط",
      "footer.download": "التحميل",
      "footer.howto": "تعليمات التثبيت",
      "footer.releases": "أحدث الإصدارات",
      "footer.copy": "© 2026 إيجاري · الإصدار 1.3.5",
      "footer.tag": "Ejari — rental ops for Egypt",
      "footer.addr":
        "العنوان: يُضاف لاحقاً من المؤسس <!-- founder: fill registered address -->",

      "sticky.title": "إيجاري 1.3.5",
      "sticky.sub": "APK لأندرويد",
      "sticky.cta": "تحميل",

      "dlpage.title": "تحميل إيجاري 1.3.5 — تعليمات التثبيت",
      "dlpage.meta":
        "حمّل إيجاري 1.3.5 لأندرويد وثبّته خطوة بخطوة. ملف APK مباشر.",
      "dlpage.brandSub": "v1.3.5",
      "dlpage.line": "ثبّت إيجاري على أندرويد.",
      "dlpage.sub":
        "ملف APK مباشر من إصدارنا الرسمي. لو عندك نسخة قديمة — امسحها الأول.",
      "dlpage.cta": "تنزيل ejari-1.3.5.apk",
      "dlpage.back": "العودة للموقع",
      "dlpage.stepsTitle": "خطوات التثبيت",
      "dlpage.stepsLede":
        "صفحة مساعدة قصيرة — زي ما بنرد على واتساب لما حد يسأل «إزاي أثبّت؟».",
      "dlpage.s1.title": "نزّل الملف",
      "dlpage.s1.body":
        "اضغط زر التنزيل واحفظ <strong>ejari-1.3.5.apk</strong> على الموبايل.",
      "dlpage.s2.title": "اسمح بالتثبيت من المصدر",
      "dlpage.s2.body":
        "أندرويد هيطلب إذن تثبيت من المتصفح أو مدير الملفات (مصادر غير معروفة). وافق مرة للمتصفح اللي نزّلت منه — ده سلوك طبيعي لأي APK برا المتجر.",
      "dlpage.s3.title": "افتح الملف وثبّت",
      "dlpage.s3.body":
        "افتح الـ APK من الإشعارات أو التحميلات، واضغط تثبيت. بعدين افتح إيجاري من الشاشة الرئيسية.",
      "dlpage.note":
        "لو التثبيت فشل بسبب تعارض التوقيع: امسح أي نسخة قديمة من إيجاري، بعدين ثبّت 1.3.5 من جديد.",
      "dlpage.retry": "تنزيل مرة تانية",
      "dlpage.privacy": "الخصوصية",
      "dlpage.terms": "الشروط",
      "dlpage.site": "الموقع",
      "dlpage.home": "الصفحة الرئيسية",
      "dlpage.support": "الدعم:",
      "dlpage.footerTag": "Android APK download",
      "dlpage.honest":
        "أندرويد 1.3.5 — قريباً على Google Play. التحميل الحالي عبر ملف APK موقّع من إيجاري.",

      "stats.loading": "جاري تحديث عدّاد التحميل…",
      "stats.total": "تم التحميل {n} مرة",
      "stats.live": "عدّاد لحظي من نقرات التحميل",
      "stats.updating": "عدّاد لحظي — جاري التحديث…",
      "stats.start": "اضغط تحميل ليبدأ العدّاد فوراً",
      "stats.offline": "عدّاد محلي — تعذّر الاتصال بالخادم",
      "stats.dedupe": "تم احتساب تحميلك · لن يُعاد العد خلال 30 ثانية",
      "stats.saved": "تم تسجيل التحميل فوراً",
      "stats.local": "محفوظ محلياً — ستتم المزامنة لاحقاً",
    },

    en: {
      "meta.title": "Ejari — Rental management in Egypt",
      "meta.desc":
        "Ejari helps tenants and owners manage rentals: contracts, payments, viewing, maintenance, and wallet. Android 1.3.5.",
      "nav.brand": "Ejari",
      "nav.trust": "Why Ejari",
      "nav.how": "How it works",
      "nav.download": "Download",
      "nav.contact": "Contact",
      "nav.home": "Home",
      "nav.lang": "عربي",
      "nav.langAria": "Switch to Arabic",
      "num.1": "1",
      "num.2": "2",
      "num.3": "3",

      "hero.brandSub": "إيجاري",
      "hero.line": "From contract to maintenance.",
      "hero.sub":
        "An Egyptian app for rental management between tenants and owners — clear process, no empty promises.",
      "hero.cta": "Download the app",
      "hero.secondary": "Learn more",

      "trust.title": "Why people use Ejari",
      "trust.lede":
        "Renting in Egypt needs clarity more than slogans. Ejari keeps the contract, payments, and maintenance in one place.",
      "trust.1.title": "Clear contracts",
      "trust.1.body":
        "Terms, duration, and amount are visible to both sides before a booking is confirmed.",
      "trust.2.title": "Payments and wallet",
      "trust.2.body":
        "Deposits, rent, and refunds are recorded in the wallet with a clear status.",
      "trust.3.title": "Maintenance tracking",
      "trust.3.body":
        "Maintenance requests are tied to the unit; technicians work from the same app.",
      "trust.4.title": "Separate roles",
      "trust.4.body":
        "Tenant, owner, technician, and admin — each sees what they need.",
      "trust.photoAlt": "Residential unit ready to rent",

      "how.title": "Three clear steps",
      "how.lede": "From choosing a unit to check-in — a straightforward path.",
      "how.1.title": "Pick the unit and duration",
      "how.1.body":
        "Daily, weekly, or monthly — review the details before you book.",
      "how.2.title": "Pay the deposit and agree",
      "how.2.body":
        "Payment is logged; the owner approves or declines based on the case.",
      "how.3.title": "Check in with QR, track maintenance",
      "how.3.body":
        "An entry code at arrival, and any maintenance request from inside the app.",

      "mission.body":
        "We aim to simplify renting in Egypt: fewer misunderstandings, more clarity between tenant and owner.",
      "mission.en": "Rental operations for Egypt — plain and practical.",

      "dl.title": "Download Ejari for Android",
      "dl.lede":
        "The current release is available as an APK. Coming soon on Google Play.",
      "dl.version":
        "Android <strong>1.3.5</strong> · size depends on your device · Android only for now",
      "dl.apk": "Download APK · 1.3.5",
      "dl.howto": "Install guide",
      "dl.upgrade":
        "If you have an older build: uninstall it first, then install 1.3.5 to avoid a signature conflict.",
      "dl.caption":
        "Illustrative photo — replace with your official unit photos later.",
      "dl.photoAlt": "Apartment interior",

      "contact.title": "Contact",
      "contact.lede": "Support and partnerships — WhatsApp or email.",
      "contact.wa": "WhatsApp · 01280083336",
      "contact.mail": "support@ejari.app",
      "contact.fb": "Facebook",
      "contact.li": "LinkedIn",
      "contact.hours":
        "We usually reply within one business day — include the app version if you hit an install issue.",

      "footer.blurb":
        "A rental and contract management app for the Egyptian market.",
      "footer.legal": "Legal",
      "footer.privacy": "Privacy policy",
      "footer.terms": "Terms of use",
      "footer.links": "Links",
      "footer.download": "Download",
      "footer.howto": "Install guide",
      "footer.releases": "Latest releases",
      "footer.copy": "© 2026 Ejari · version 1.3.5",
      "footer.tag": "Ejari — rental ops for Egypt",
      "footer.addr":
        "Address: to be added by founder <!-- founder: fill registered address -->",

      "sticky.title": "Ejari 1.3.5",
      "sticky.sub": "Android APK",
      "sticky.cta": "Download",

      "dlpage.title": "Download Ejari 1.3.5 — install guide",
      "dlpage.meta":
        "Download Ejari 1.3.5 for Android and install step by step. Direct APK.",
      "dlpage.brandSub": "v1.3.5",
      "dlpage.line": "Install Ejari on Android.",
      "dlpage.sub":
        "Direct APK from our official release. If you already have an older build — remove it first.",
      "dlpage.cta": "Download ejari-1.3.5.apk",
      "dlpage.back": "Back to site",
      "dlpage.stepsTitle": "Install steps",
      "dlpage.stepsLede":
        "A short help page — the same answer we give on WhatsApp when someone asks how to install.",
      "dlpage.s1.title": "Download the file",
      "dlpage.s1.body":
        "Tap download and save <strong>ejari-1.3.5.apk</strong> on your phone.",
      "dlpage.s2.title": "Allow install from that source",
      "dlpage.s2.body":
        "Android will ask for permission to install from the browser or file manager (unknown sources). Allow it once for the app you downloaded with — normal for any APK outside the Play Store.",
      "dlpage.s3.title": "Open the file and install",
      "dlpage.s3.body":
        "Open the APK from notifications or Downloads, tap Install, then open Ejari from your home screen.",
      "dlpage.note":
        "If install fails due to a signature conflict: remove any older Ejari build, then install 1.3.5 again.",
      "dlpage.retry": "Download again",
      "dlpage.privacy": "Privacy",
      "dlpage.terms": "Terms",
      "dlpage.site": "Site",
      "dlpage.home": "Home page",
      "dlpage.support": "Support:",
      "dlpage.footerTag": "Android APK download",
      "dlpage.honest":
        "Android 1.3.5 — coming soon on Google Play. Current download is a signed Ejari APK.",

      "stats.loading": "Updating download count…",
      "stats.total": "Downloaded {n} times",
      "stats.live": "Live counter from download taps",
      "stats.updating": "Live counter — refreshing…",
      "stats.start": "Tap download to start the counter",
      "stats.offline": "Local count — could not reach the server",
      "stats.dedupe": "Your download was counted · no recount for 30 seconds",
      "stats.saved": "Download recorded",
      "stats.local": "Saved locally — will sync later",
    },
  };

  function normalize(lang) {
    return lang === "en" ? "en" : "ar";
  }

  function readQueryLang() {
    try {
      var q = new URLSearchParams(window.location.search).get("lang");
      if (q === "en" || q === "ar") return q;
    } catch (_) {}
    return null;
  }

  function readStored() {
    try {
      var v = localStorage.getItem(STORAGE_KEY);
      if (v === "en" || v === "ar") return v;
    } catch (_) {}
    return null;
  }

  function detect() {
    return normalize(readQueryLang() || readStored() || "ar");
  }

  function t(key, lang) {
    var L = STR[lang] || STR.ar;
    return (L[key] != null ? L[key] : STR.ar[key]) || key;
  }

  function apply(lang) {
    lang = normalize(lang);
    var root = document.documentElement;
    root.lang = lang === "en" ? "en" : "ar";
    root.dir = lang === "en" ? "ltr" : "rtl";
    root.setAttribute("data-lang", lang);

    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (_) {}

    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (!key) return;
      var val = t(key, lang);
      if (el.hasAttribute("data-i18n-html")) {
        el.innerHTML = val;
      } else {
        el.textContent = val;
      }
    });

    document.querySelectorAll("[data-i18n-aria]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-aria");
      if (key) el.setAttribute("aria-label", t(key, lang));
    });

    document.querySelectorAll("[data-i18n-alt]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-alt");
      if (key) el.setAttribute("alt", t(key, lang));
    });

    var titleKey = document.body.getAttribute("data-title-key") || "meta.title";
    var descKey = document.body.getAttribute("data-desc-key") || "meta.desc";
    document.title = t(titleKey, lang);
    var metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.setAttribute("content", t(descKey, lang));

    document.querySelectorAll("[data-lang-toggle]").forEach(function (btn) {
      btn.setAttribute("aria-label", t("nav.langAria", lang));
      var label = btn.querySelector("[data-lang-label]");
      if (label) label.textContent = t("nav.lang", lang);
      btn.setAttribute("data-next", lang === "ar" ? "en" : "ar");
    });

    // Keep share URL clean but reflect language for deep links
    try {
      var url = new URL(window.location.href);
      if (lang === "en") url.searchParams.set("lang", "en");
      else url.searchParams.delete("lang");
      window.history.replaceState({}, "", url.pathname + url.search + url.hash);
    } catch (_) {}

    window.dispatchEvent(
      new CustomEvent("ejari:lang", { detail: { lang: lang } })
    );
  }

  function toggle() {
    apply(document.documentElement.getAttribute("data-lang") === "en" ? "ar" : "en");
  }

  function init() {
    apply(detect());
    document.querySelectorAll("[data-lang-toggle]").forEach(function (btn) {
      btn.addEventListener("click", function (e) {
        e.preventDefault();
        toggle();
      });
    });
  }

  window.EjariI18n = {
    t: t,
    apply: apply,
    toggle: toggle,
    getLang: function () {
      return normalize(document.documentElement.getAttribute("data-lang") || "ar");
    },
    STR: STR,
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
