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
      "a11y.skip": "تخطّي إلى المحتوى",
      "nav.brand": "إيجاري",
      "nav.trust": "ليه إيجاري",
      "nav.about": "من نحن",
      "nav.how": "كيف يشتغل",
      "nav.download": "التحميل",
      "nav.contact": "تواصل",
      "nav.home": "الرئيسية",
      "nav.lang": "English",
      "nav.langAria": "التبديل إلى الإنجليزية",
      "nav.aria": "أقسام الصفحة",
      "nav.ariaDl": "تنقل",
      "nav.menuOpen": "فتح القائمة",
      "nav.menuClose": "إغلاق القائمة",
      "num.1": "١",
      "num.2": "٢",
      "num.3": "٣",

      "hero.aria": "مقدمة إيجاري",
      "hero.brandSub": "Ejari",
      "hero.line": "من العقد… لحد الصيانة.",
      "hero.sub":
        "تطبيق مصري لإدارة الإيجار بين المستأجر والمالك — بدون لفّ ولا وعود فاضيّة.",
      "hero.cta": "حمّل التطبيق",
      "hero.secondary": "من نحن",

      "trust.title": "الإيجار محتاج ترتيب، مش شعارات",
      "trust.lede":
        "في مصر الاتفاق بيتقال شفهي كتير. إيجاري بيرتّب العقد والدفع والصيانة في مكان واحد عشان الطرفين يشوفوا نفس الصورة.",
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

      "about.title": "من نحن",
      "about.lede":
        "إيجاري مشروع مصري لتشغيل الإيجار اليومي: من الاتفاق على الوحدة لحد طلب الصيانة — بدون ما نبيع أرقام مستخدمين ولا وعود مش موجودة.",
      "about.mission":
        "هدفنا نقلّل سوء التفاهم بين المستأجر والمالك: بنود واضحة، دفع بحالة ظاهرة، وصيانة مربوطة بالوحدة مش بالواتساب المتفرّق.",
      "about.place": "القاهرة، مصر",

      "roles.title": "مين بيغطي التطبيق",
      "roles.lede":
        "نطاق المنتج — مش إحصائية تحميلات. أربعة أدوار في نفس المنظومة:",
      "roles.tenant.label": "مستأجر",
      "roles.tenant.body": "حجز، عقد، دفع، دخول بـ QR، وطلب صيانة.",
      "roles.owner.label": "مالك",
      "roles.owner.body": "وحدات، موافقات، محفظة، ومتابعة طلبات.",
      "roles.tech.label": "فني",
      "roles.tech.body": "مهام صيانة مربوطة بالوحدة من جوّه التطبيق.",
      "roles.admin.label": "إدارة",
      "roles.admin.body": "تشغيل المنصة ومتابعة الحالات من لوحة الإدارة.",

      "how.title": "من الاختيار لحد الدخول",
      "how.lede": "ثلاث خطوات واضحة — من غير مسار معقّد.",
      "how.1.title": "اختار الوحدة والمدة",
      "how.1.body": "يومي، أسبوعي، أو شهري — وتشوف التفاصيل قبل ما تحجز.",
      "how.2.title": "ادفع العربون واتفق",
      "how.2.body": "الدفع يتسجّل، والمالك يوافق أو يرد حسب الحالة.",
      "how.3.title": "ادخل بـ QR وتابع الصيانة",
      "how.3.body":
        "رمز دخول عند الوصول، ومتابعة أي طلب صيانة من جوه التطبيق.",

      "mission.strip": "وضوح بين الطرفين — أقل لفّ في الإيجار.",

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
      "contact.waShort": "واتساب",
      "contact.mail": "support@ejari.app",
      "contact.fb": "فيسبوك",
      "contact.li": "لينكدإن",
      "contact.hours":
        "الدعم عادةً خلال يوم عمل — اكتب رقم الإصدار لو فيه مشكلة تثبيت.",

      "footer.blurb":
        "تطبيق لإدارة الإيجار والعقود في السوق المصري — من القاهرة.",
      "footer.place": "القاهرة، مصر",
      "footer.legal": "قانوني",
      "footer.privacy": "سياسة الخصوصية",
      "footer.terms": "الشروط والأحكام",
      "footer.links": "روابط",
      "footer.download": "التحميل",
      "footer.howto": "تعليمات التثبيت",
      "footer.releases": "أحدث الإصدارات",
      "footer.copy": "© 2026 إيجاري · الإصدار 1.3.5",
      "footer.tag": "Ejari — rental ops for Egypt",

      "sticky.aria": "تحميل سريع",
      "sticky.title": "إيجاري 1.3.5",
      "sticky.sub": "APK لأندرويد",
      "sticky.cta": "تحميل",

      "dlpage.title": "تحميل إيجاري 1.3.5 — تعليمات التثبيت",
      "dlpage.meta":
        "حمّل إيجاري 1.3.5 لأندرويد وثبّته خطوة بخطوة. ملف APK مباشر.",
      "dlpage.aria": "تحميل التطبيق",
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
      "dlpage.footerTag": "تحميل APK لأندرويد",
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
      "a11y.skip": "Skip to content",
      "nav.brand": "Ejari",
      "nav.trust": "Why Ejari",
      "nav.about": "About",
      "nav.how": "How it works",
      "nav.download": "Download",
      "nav.contact": "Contact",
      "nav.home": "Home",
      "nav.lang": "عربي",
      "nav.langAria": "Switch to Arabic",
      "nav.aria": "Page sections",
      "nav.ariaDl": "Navigation",
      "nav.menuOpen": "Open menu",
      "nav.menuClose": "Close menu",
      "num.1": "1",
      "num.2": "2",
      "num.3": "3",

      "hero.aria": "Ejari introduction",
      "hero.brandSub": "إيجاري",
      "hero.line": "From contract to maintenance.",
      "hero.sub":
        "An Egyptian app for rental management between tenants and owners — clear process, no empty promises.",
      "hero.cta": "Download the app",
      "hero.secondary": "About us",

      "trust.title": "Renting needs order, not slogans",
      "trust.lede":
        "In Egypt, deals are often verbal. Ejari keeps the contract, payments, and maintenance in one place so both sides see the same picture.",
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

      "about.title": "About us",
      "about.lede":
        "Ejari is an Egyptian project for day-to-day rental operations: from agreeing on a unit to filing maintenance — without fake user counts or promises we cannot keep.",
      "about.mission":
        "We aim to cut misunderstandings between tenant and owner: clear terms, visible payment status, and maintenance tied to the unit — not scattered WhatsApp threads.",
      "about.place": "Cairo, Egypt",

      "roles.title": "Who the app covers",
      "roles.lede":
        "Product scope — not a download statistic. Four roles in one system:",
      "roles.tenant.label": "Tenant",
      "roles.tenant.body":
        "Booking, contract, payment, QR check-in, and maintenance requests.",
      "roles.owner.label": "Owner",
      "roles.owner.body":
        "Units, approvals, wallet, and request follow-up.",
      "roles.tech.label": "Technician",
      "roles.tech.body":
        "Maintenance tasks tied to the unit from inside the app.",
      "roles.admin.label": "Admin",
      "roles.admin.body":
        "Platform operations and status follow-up from the admin panel.",

      "how.title": "From pick to check-in",
      "how.lede": "Three clear steps — no maze.",
      "how.1.title": "Pick the unit and duration",
      "how.1.body":
        "Daily, weekly, or monthly — review the details before you book.",
      "how.2.title": "Pay the deposit and agree",
      "how.2.body":
        "Payment is logged; the owner approves or declines based on the case.",
      "how.3.title": "Check in with QR, track maintenance",
      "how.3.body":
        "An entry code at arrival, and any maintenance request from inside the app.",

      "mission.strip": "Clarity between both sides — less friction in renting.",

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
      "contact.waShort": "WhatsApp",
      "contact.mail": "support@ejari.app",
      "contact.fb": "Facebook",
      "contact.li": "LinkedIn",
      "contact.hours":
        "We usually reply within one business day — include the app version if you hit an install issue.",

      "footer.blurb":
        "A rental and contract management app for the Egyptian market — based in Cairo.",
      "footer.place": "Cairo, Egypt",
      "footer.legal": "Legal",
      "footer.privacy": "Privacy policy",
      "footer.terms": "Terms of use",
      "footer.links": "Links",
      "footer.download": "Download",
      "footer.howto": "Install guide",
      "footer.releases": "Latest releases",
      "footer.copy": "© 2026 Ejari · version 1.3.5",
      "footer.tag": "Ejari — rental ops for Egypt",

      "sticky.aria": "Quick download",
      "sticky.title": "Ejari 1.3.5",
      "sticky.sub": "Android APK",
      "sticky.cta": "Download",

      "dlpage.title": "Download Ejari 1.3.5 — install guide",
      "dlpage.meta":
        "Download Ejari 1.3.5 for Android and install step by step. Direct APK.",
      "dlpage.aria": "App download",
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
    if (L[key] != null) return L[key];
    if (STR.ar[key] != null) return STR.ar[key];
    return null;
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
      /* Never paint raw keys over the HTML fallback copy */
      if (val == null) return;
      if (el.hasAttribute("data-i18n-html")) {
        el.innerHTML = val;
      } else {
        el.textContent = val;
      }
    });

    document.querySelectorAll("[data-i18n-aria]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-aria");
      var val = key ? t(key, lang) : null;
      if (val != null) el.setAttribute("aria-label", val);
    });

    document.querySelectorAll("[data-i18n-alt]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-alt");
      var val = key ? t(key, lang) : null;
      if (val != null) el.setAttribute("alt", val);
    });

    var titleKey = document.body.getAttribute("data-title-key") || "meta.title";
    var descKey = document.body.getAttribute("data-desc-key") || "meta.desc";
    var titleVal = t(titleKey, lang);
    if (titleVal != null) document.title = titleVal;
    var metaDesc = document.querySelector('meta[name="description"]');
    var descVal = t(descKey, lang);
    if (metaDesc && descVal != null) metaDesc.setAttribute("content", descVal);

    document.querySelectorAll("[data-lang-toggle]").forEach(function (btn) {
      var aria = t("nav.langAria", lang);
      if (aria != null) btn.setAttribute("aria-label", aria);
      var label = btn.querySelector("[data-lang-label]");
      var langLabel = t("nav.lang", lang);
      if (label && langLabel != null) label.textContent = langLabel;
      btn.setAttribute("data-next", lang === "ar" ? "en" : "ar");
    });

    document.querySelectorAll("[data-nav-toggle]").forEach(function (btn) {
      var open = btn.getAttribute("aria-expanded") === "true";
      var menuKey = open ? "nav.menuClose" : "nav.menuOpen";
      var menuAria = t(menuKey, lang);
      if (menuAria != null) btn.setAttribute("aria-label", menuAria);
    });

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
