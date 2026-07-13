/**
 * Ejari APK download counter
 * - Instant local click counter (feels responsive on tap)
 * - Merged with GitHub Releases download_count when available
 */
(function () {
  const REPO = "m7moud2/ejari-web";
  const API_RELEASES = `https://api.github.com/repos/${REPO}/releases?per_page=100`;
  const POLL_MS = 60_000;
  const LOCAL_KEY = "ejari_apk_click_count_v1";
  const SESSION_BUMP_KEY = "ejari_apk_click_session_bumps";

  function isEjariApk(name) {
    if (!name || !/\.apk$/i.test(name)) return false;
    if (/^keyo/i.test(name)) return false;
    return true;
  }

  function formatAr(n) {
    try {
      return Number(n).toLocaleString("ar-EG");
    } catch (_) {
      return String(n);
    }
  }

  function readLocalClicks() {
    try {
      const n = parseInt(localStorage.getItem(LOCAL_KEY) || "0", 10);
      return Number.isFinite(n) && n > 0 ? n : 0;
    } catch (_) {
      return 0;
    }
  }

  function writeLocalClicks(n) {
    try {
      localStorage.setItem(LOCAL_KEY, String(Math.max(0, n | 0)));
    } catch (_) {}
  }

  function bumpLocalClick() {
    const next = readLocalClicks() + 1;
    writeLocalClicks(next);
    return next;
  }

  async function fetchGithubStats() {
    const res = await fetch(API_RELEASES, {
      headers: { Accept: "application/vnd.github+json" },
    });
    if (!res.ok) throw new Error("GitHub API " + res.status);
    const releases = await res.json();
    if (!Array.isArray(releases)) throw new Error("Unexpected API payload");

    let total = 0;
    let current = 0;
    let currentTag = "";
    let currentAsset = "";

    releases.forEach((rel, idx) => {
      (rel.assets || []).forEach((asset) => {
        if (!isEjariApk(asset.name)) return;
        const count = Number(asset.download_count) || 0;
        total += count;
        if (idx === 0) {
          current += count;
          currentTag = (rel.tag_name || "").replace(/^v/, "");
          currentAsset = asset.name;
        }
      });
    });

    return { total, current, currentTag, currentAsset };
  }

  function displayTotal(githubTotal, localClicks) {
    // Show the higher of GitHub truth vs local instant clicks so the
    // counter never feels stuck while GitHub CDN lag catches up.
    return Math.max(Number(githubTotal) || 0, Number(localClicks) || 0);
  }

  let lastGithub = { total: 0, current: 0, currentTag: "", currentAsset: "" };

  function render(root, stats) {
    const local = readLocalClicks();
    const total = displayTotal(stats.total, local);
    const totalEl = root.querySelector("[data-dl-total]");
    const currentEl = root.querySelector("[data-dl-current]");
    const statusEl = root.querySelector("[data-dl-status]");

    if (totalEl) {
      totalEl.textContent = `تم التحميل ${formatAr(total)} مرة`;
    }
    if (currentEl) {
      const tag = stats.currentTag ? `v${stats.currentTag}` : "الحالي";
      const currentShown = displayTotal(stats.current, local);
      currentEl.textContent = `${tag}: ${formatAr(currentShown)} تحميل`;
    }
    if (statusEl) {
      statusEl.textContent =
        local > (stats.total || 0)
          ? "يتحدث فوراً عند الضغط + مزامنة GitHub"
          : "من عدّاد GitHub + نقرات الصفحة";
      statusEl.hidden = false;
    }
    root.classList.add("is-ready");
    root.setAttribute("aria-busy", "false");
  }

  function renderLocalOnly(root) {
    const local = readLocalClicks();
    const totalEl = root.querySelector("[data-dl-total]");
    const currentEl = root.querySelector("[data-dl-current]");
    const statusEl = root.querySelector("[data-dl-status]");
    if (totalEl) {
      totalEl.textContent =
        local > 0
          ? `تم التحميل ${formatAr(local)} مرة`
          : "اضغط تحميل ليبدأ العدّاد فوراً";
    }
    if (currentEl && local > 0) {
      currentEl.textContent = `نقرات هذه الصفحة: ${formatAr(local)}`;
    }
    if (statusEl) {
      statusEl.textContent = "عدّاد فوري — جاري مزامنة GitHub…";
      statusEl.hidden = false;
    }
    root.classList.add("is-ready");
    root.setAttribute("aria-busy", "false");
  }

  function renderError(root) {
    renderLocalOnly(root);
  }

  function paintAll() {
    const roots = document.querySelectorAll("[data-ejari-download-stats]");
    roots.forEach((root) => render(root, lastGithub));
  }

  async function refreshAll() {
    const roots = document.querySelectorAll("[data-ejari-download-stats]");
    if (!roots.length) return;
    // Paint immediately from local so UI never sits on "جاري الحساب…"
    roots.forEach((root) => renderLocalOnly(root));
    try {
      lastGithub = await fetchGithubStats();
      // Seed local from GitHub once so first-time visitors see a real base.
      if (readLocalClicks() === 0 && lastGithub.total > 0) {
        writeLocalClicks(lastGithub.total);
      }
      roots.forEach((root) => render(root, lastGithub));
    } catch (_) {
      roots.forEach((root) => renderError(root));
    }
  }

  function onDownloadClick(event) {
    const link = event.target.closest(
      "a[data-apk-link], a.btn-primary[href*='.apk'], a.nav-cta[href*='.apk'], a[href*='ejari-'][href$='.apk']"
    );
    if (!link) return;
    bumpLocalClick();
    paintAll();
    // Allow default navigation to the APK; counter already updated.
  }

  function init() {
    document.addEventListener("click", onDownloadClick, true);
    refreshAll();
    setInterval(refreshAll, POLL_MS);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  window.EjariDownloadStats = {
    refresh: refreshAll,
    fetchStats: fetchGithubStats,
    bump: bumpLocalClick,
  };
})();
