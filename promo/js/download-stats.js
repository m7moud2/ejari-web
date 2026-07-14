/**
 * Ejari APK download counter — realtime click counter
 * Primary: Firestore public_stats/downloads.total (instant on click)
 * Secondary: optimistic UI + local cache; 30s session dedupe
 */
(function () {
  const FIREBASE = {
    apiKey: "AIzaSyBxVVVTRFiPaLvTkXFCh-rYVPSC4ImagbY",
    projectId: "keyo-elite-1",
  };
  const DOC_PATH =
    "projects/" +
    FIREBASE.projectId +
    "/databases/(default)/documents/public_stats/downloads";
  const DOC_URL =
    "https://firestore.googleapis.com/v1/" +
    DOC_PATH +
    "?key=" +
    encodeURIComponent(FIREBASE.apiKey);
  const COMMIT_URL =
    "https://firestore.googleapis.com/v1/projects/" +
    FIREBASE.projectId +
    "/databases/(default)/documents:commit?key=" +
    encodeURIComponent(FIREBASE.apiKey);

  const CACHE_KEY = "ejari_apk_dl_total_v2";
  const SESSION_TS_KEY = "ejari_apk_dl_last_bump_ts";
  const DEDUPE_MS = 30_000;

  let displayedTotal = 0;
  let remoteReady = false;

  function formatAr(n) {
    try {
      return Number(n).toLocaleString("ar-EG");
    } catch (_) {
      return String(n);
    }
  }

  function readCache() {
    try {
      const n = parseInt(localStorage.getItem(CACHE_KEY) || "0", 10);
      return Number.isFinite(n) && n > 0 ? n : 0;
    } catch (_) {
      return 0;
    }
  }

  function writeCache(n) {
    try {
      localStorage.setItem(CACHE_KEY, String(Math.max(0, n | 0)));
    } catch (_) {}
  }

  function recentSessionBump() {
    try {
      const ts = parseInt(sessionStorage.getItem(SESSION_TS_KEY) || "0", 10);
      if (!Number.isFinite(ts) || ts <= 0) return false;
      return Date.now() - ts < DEDUPE_MS;
    } catch (_) {
      return false;
    }
  }

  function markSessionBump() {
    try {
      sessionStorage.setItem(SESSION_TS_KEY, String(Date.now()));
    } catch (_) {}
  }

  function renderAll(total, statusText) {
    displayedTotal = Math.max(0, total | 0);
    writeCache(displayedTotal);
    const roots = document.querySelectorAll("[data-ejari-download-stats]");
    roots.forEach((root) => {
      const totalEl = root.querySelector("[data-dl-total]");
      const currentEl = root.querySelector("[data-dl-current]");
      const statusEl = root.querySelector("[data-dl-status]");
      if (totalEl) {
        totalEl.textContent = `تم التحميل ${formatAr(displayedTotal)} مرة`;
      }
      if (currentEl) {
        currentEl.textContent = "";
        currentEl.hidden = true;
      }
      if (statusEl) {
        statusEl.textContent = statusText || "عدّاد لحظي من نقرات التحميل";
        statusEl.hidden = false;
      }
      root.classList.add("is-ready");
      root.setAttribute("aria-busy", "false");
    });
  }

  function parseTotal(payload) {
    if (!payload || !payload.fields || !payload.fields.total) return null;
    const t = payload.fields.total;
    if (t.integerValue != null) return parseInt(t.integerValue, 10) || 0;
    if (t.doubleValue != null) return Math.floor(Number(t.doubleValue)) || 0;
    return null;
  }

  async function fetchRemoteTotal() {
    const res = await fetch(DOC_URL, { method: "GET" });
    if (res.status === 404) return 0;
    if (!res.ok) throw new Error("Firestore GET " + res.status);
    const data = await res.json();
    const total = parseTotal(data);
    if (total == null) throw new Error("Invalid Firestore payload");
    return total;
  }

  async function createRemote(total) {
    const url =
      "https://firestore.googleapis.com/v1/projects/" +
      FIREBASE.projectId +
      "/databases/(default)/documents/public_stats?documentId=downloads&key=" +
      encodeURIComponent(FIREBASE.apiKey);
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fields: { total: { integerValue: String(total) } },
      }),
    });
    if (!res.ok) {
      const err = await res.text().catch(() => "");
      throw new Error("Firestore CREATE " + res.status + " " + err);
    }
    return total;
  }

  async function incrementRemote() {
    const res = await fetch(COMMIT_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        writes: [
          {
            transform: {
              document: DOC_PATH,
              fieldTransforms: [
                {
                  fieldPath: "total",
                  increment: { integerValue: "1" },
                },
              ],
            },
          },
        ],
      }),
    });
    if (res.status === 404 || res.status === 400) {
      // Doc missing — create with 1 (allowed by rules).
      return createRemote(1);
    }
    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      const msg =
        (errBody.error && errBody.error.message) || String(res.status);
      // NOT_FOUND when document does not exist
      if (/NOT_FOUND|No document to update|not found/i.test(msg)) {
        return createRemote(1);
      }
      throw new Error("Firestore INC " + msg);
    }
    const data = await res.json();
    const writeResult =
      data.writeResults && data.writeResults[0] && data.writeResults[0].transformResults;
    if (writeResult && writeResult[0] && writeResult[0].integerValue != null) {
      return parseInt(writeResult[0].integerValue, 10) || displayedTotal + 1;
    }
    // Commit succeeded but no transform echo — re-fetch
    return fetchRemoteTotal();
  }

  async function refreshFromRemote() {
    const cached = readCache();
    if (cached > 0) {
      renderAll(cached, "عدّاد لحظي — جاري التحديث…");
    } else {
      renderAll(0, "اضغط تحميل ليبدأ العدّاد فوراً");
    }
    try {
      const total = await fetchRemoteTotal();
      remoteReady = true;
      renderAll(Math.max(total, cached), "عدّاد لحظي من نقرات التحميل");
    } catch (_) {
      if (cached > 0) {
        renderAll(cached, "عدّاد محلي — تعذّر الاتصال بالخادم");
      } else {
        renderAll(0, "اضغط تحميل ليبدأ العدّاد فوراً");
      }
    }
  }

  async function onDownloadClick(event) {
    const link = event.target.closest(
      "a[data-apk-link], a#download-btn, a.btn-primary[href*='.apk'], a.nav-cta[href*='.apk'], a[href*='ejari-'][href$='.apk'], a[href*='/releases/download/'][href$='.apk']"
    );
    if (!link) return;

    if (recentSessionBump()) {
      // Same browser session within 30s — show count, don't double-count.
      renderAll(
        displayedTotal || readCache(),
        "تم احتساب تحميلك · لن يُعاد العد خلال 30 ثانية"
      );
      return;
    }

    markSessionBump();
    const optimistic = (displayedTotal || readCache()) + 1;
    renderAll(optimistic, "تم تسجيل التحميل فوراً");

    try {
      const remote = await incrementRemote();
      remoteReady = true;
      renderAll(Math.max(remote, optimistic), "عدّاد لحظي من نقرات التحميل");
    } catch (_) {
      // Keep optimistic local count if remote write fails.
      renderAll(optimistic, "محفوظ محلياً — ستتم المزامنة لاحقاً");
    }
  }

  function init() {
    document.addEventListener("click", onDownloadClick, true);
    refreshFromRemote();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  window.EjariDownloadStats = {
    refresh: refreshFromRemote,
    getTotal: function () {
      return displayedTotal;
    },
  };
})();
