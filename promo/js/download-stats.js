/**
 * Ejari APK download counter — realtime click counter
 * Primary: Firestore public_stats/downloads.total (instant on click)
 * Secondary: optimistic UI + local cache; 30s session dedupe
 * Messages follow EjariI18n language when available.
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
  let lastStatusKey = "stats.live";
  let remoteReady = false;

  function lang() {
    if (window.EjariI18n && window.EjariI18n.getLang) {
      return window.EjariI18n.getLang();
    }
    return document.documentElement.getAttribute("data-lang") === "en"
      ? "en"
      : "ar";
  }

  function msg(key, vars) {
    var text = null;
    if (window.EjariI18n && window.EjariI18n.t) {
      text = window.EjariI18n.t(key, lang());
    }
    /* Never paint raw keys — leave existing DOM text if missing */
    if (text == null) return null;
    if (vars && vars.n != null) {
      text = String(text).replace("{n}", formatAr(vars.n));
    }
    return text;
  }

  function formatAr(n) {
    try {
      return Number(n).toLocaleString(lang() === "en" ? "en-US" : "ar-EG");
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

  function renderAll(total, statusKey) {
    displayedTotal = Math.max(0, total | 0);
    writeCache(displayedTotal);
    if (statusKey) lastStatusKey = statusKey;
    const roots = document.querySelectorAll("[data-ejari-download-stats]");
    roots.forEach((root) => {
      const totalEl = root.querySelector("[data-dl-total]");
      const currentEl = root.querySelector("[data-dl-current]");
      const statusEl = root.querySelector("[data-dl-status]");
      if (totalEl) {
        const totalText = msg("stats.total", { n: displayedTotal });
        if (totalText != null) totalEl.textContent = totalText;
      }
      if (currentEl) {
        currentEl.textContent = "";
        currentEl.hidden = true;
      }
      if (statusEl) {
        const statusText = msg(lastStatusKey);
        if (statusText != null) {
          statusEl.textContent = statusText;
          statusEl.hidden = false;
        }
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
      return createRemote(1);
    }
    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      const msgText =
        (errBody.error && errBody.error.message) || String(res.status);
      if (/NOT_FOUND|No document to update|not found/i.test(msgText)) {
        return createRemote(1);
      }
      throw new Error("Firestore INC " + msgText);
    }
    const data = await res.json();
    const writeResult =
      data.writeResults &&
      data.writeResults[0] &&
      data.writeResults[0].transformResults;
    if (writeResult && writeResult[0] && writeResult[0].integerValue != null) {
      return parseInt(writeResult[0].integerValue, 10) || displayedTotal + 1;
    }
    return fetchRemoteTotal();
  }

  async function refreshFromRemote() {
    const cached = readCache();
    if (cached > 0) {
      renderAll(cached, "stats.updating");
    } else {
      renderAll(0, "stats.start");
    }
    try {
      const total = await fetchRemoteTotal();
      remoteReady = true;
      renderAll(Math.max(total, cached), "stats.live");
    } catch (_) {
      if (cached > 0) {
        renderAll(cached, "stats.offline");
      } else {
        renderAll(0, "stats.start");
      }
    }
  }

  async function onDownloadClick(event) {
    const link = event.target.closest(
      "a[data-apk-link], a#download-btn, a.btn-primary[href*='.apk'], a.nav-cta[href*='.apk'], a[href*='ejari-'][href$='.apk'], a[href*='/releases/download/'][href$='.apk']"
    );
    if (!link) return;

    if (recentSessionBump()) {
      renderAll(displayedTotal || readCache(), "stats.dedupe");
      return;
    }

    markSessionBump();
    const optimistic = (displayedTotal || readCache()) + 1;
    renderAll(optimistic, "stats.saved");

    try {
      const remote = await incrementRemote();
      remoteReady = true;
      renderAll(Math.max(remote, optimistic), "stats.live");
    } catch (_) {
      renderAll(optimistic, "stats.local");
    }
  }

  function init() {
    document.addEventListener("click", onDownloadClick, true);
    window.addEventListener("ejari:lang", function () {
      renderAll(displayedTotal || readCache(), lastStatusKey);
    });
    // Wait a tick so i18n can apply first if scripts load out of order
    if (window.EjariI18n) {
      refreshFromRemote();
    } else {
      setTimeout(refreshFromRemote, 0);
    }
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
