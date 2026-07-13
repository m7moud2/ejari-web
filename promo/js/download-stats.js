/**
 * Ejari APK download counter — GitHub Releases asset download_count
 * Public API (no auth). Counts real CDN downloads from release assets.
 */
(function () {
  const REPO = "m7moud2/ejari-web";
  const API_RELEASES = `https://api.github.com/repos/${REPO}/releases?per_page=100`;
  const POLL_MS = 60_000;

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

  async function fetchStats() {
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

  function render(root, stats) {
    const totalEl = root.querySelector("[data-dl-total]");
    const currentEl = root.querySelector("[data-dl-current]");
    const statusEl = root.querySelector("[data-dl-status]");

    if (totalEl) {
      totalEl.textContent = `تم التحميل ${formatAr(stats.total)} مرة`;
    }
    if (currentEl) {
      const tag = stats.currentTag ? `v${stats.currentTag}` : "الحالي";
      currentEl.textContent = `${tag}: ${formatAr(stats.current)} تحميل`;
    }
    if (statusEl) {
      statusEl.textContent = "من عدّاد GitHub الحقيقي";
      statusEl.hidden = false;
    }
    root.classList.add("is-ready");
    root.setAttribute("aria-busy", "false");
  }

  function renderError(root) {
    const totalEl = root.querySelector("[data-dl-total]");
    if (totalEl && !root.classList.contains("is-ready")) {
      totalEl.textContent = "عدد التحميلات غير متاح مؤقتًا";
    }
    root.setAttribute("aria-busy", "false");
  }

  async function refreshAll() {
    const roots = document.querySelectorAll("[data-ejari-download-stats]");
    if (!roots.length) return;
    try {
      const stats = await fetchStats();
      roots.forEach((root) => render(root, stats));
    } catch (_) {
      roots.forEach((root) => renderError(root));
    }
  }

  function init() {
    refreshAll();
    setInterval(refreshAll, POLL_MS);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  window.EjariDownloadStats = { refresh: refreshAll, fetchStats };
})();
