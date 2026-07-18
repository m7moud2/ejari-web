/**
 * Promo chrome: sticky nav, mobile menu (a11y), sticky CTA hide, reveals.
 * No frameworks. Respects prefers-reduced-motion.
 */
(function () {
  function prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }

  function isDesktopNav() {
    return window.matchMedia("(min-width: 861px)").matches;
  }

  function initReady() {
    document.body.classList.add("is-ready");
  }

  function initNav() {
    var header = document.querySelector("[data-site-nav]");
    if (!header) return;

    var toggle = header.querySelector("[data-nav-toggle]");
    var links = header.querySelector(".nav-links");
    var lastFocus = null;

    function setSolid() {
      var solid = window.scrollY > 18 || header.classList.contains("is-open");
      header.classList.toggle("is-solid", solid);
    }

    function menuLabel(open) {
      var key = open ? "nav.menuClose" : "nav.menuOpen";
      if (window.EjariI18n && window.EjariI18n.t) {
        return window.EjariI18n.t(key, window.EjariI18n.getLang());
      }
      return null;
    }

    function syncMenuA11y(open) {
      if (!links) return;
      if (isDesktopNav()) {
        links.removeAttribute("aria-hidden");
        return;
      }
      links.setAttribute("aria-hidden", open ? "false" : "true");
    }

    function setOpen(open) {
      header.classList.toggle("is-open", open);
      document.body.classList.toggle("is-nav-open", open);
      syncMenuA11y(open);
      if (toggle) {
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
        var label = menuLabel(open);
        if (label) toggle.setAttribute("aria-label", label);
      }
      setSolid();

      if (open) {
        lastFocus = document.activeElement;
        var first = links && links.querySelector("a");
        if (first) {
          window.setTimeout(function () {
            first.focus();
          }, 40);
        }
      } else if (lastFocus && typeof lastFocus.focus === "function") {
        lastFocus.focus();
        lastFocus = null;
      }
    }

    syncMenuA11y(false);
    setSolid();
    window.addEventListener("scroll", setSolid, { passive: true });

    if (toggle) {
      toggle.addEventListener("click", function () {
        setOpen(!header.classList.contains("is-open"));
      });
    }

    if (links) {
      links.querySelectorAll("a").forEach(function (a) {
        a.addEventListener("click", function () {
          setOpen(false);
        });
      });
    }

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && header.classList.contains("is-open")) {
        setOpen(false);
        return;
      }
      if (
        e.key !== "Tab" ||
        !header.classList.contains("is-open") ||
        !links ||
        !toggle ||
        isDesktopNav()
      ) {
        return;
      }
      var focusables = [toggle];
      var langBtn = header.querySelector("[data-lang-toggle]");
      if (langBtn) focusables.push(langBtn);
      Array.prototype.forEach.call(links.querySelectorAll("a"), function (a) {
        focusables.push(a);
      });
      var first = focusables[0];
      var last = focusables[focusables.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    });

    window.addEventListener("resize", function () {
      if (isDesktopNav()) {
        setOpen(false);
        syncMenuA11y(false);
      } else {
        syncMenuA11y(header.classList.contains("is-open"));
      }
    });
  }

  function initStickyDl() {
    var bar = document.querySelector(".sticky-dl");
    if (!bar || !("IntersectionObserver" in window)) return;

    var anchors = document.querySelectorAll(
      "main a[data-apk-link], #download"
    );
    if (!anchors.length) return;

    var hit = Object.create(null);
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          var id = entry.target.getAttribute("data-sticky-watch");
          hit[id] = entry.isIntersecting;
        });
        var any = false;
        for (var k in hit) {
          if (hit[k]) {
            any = true;
            break;
          }
        }
        bar.classList.toggle("is-away", any);
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.18 }
    );

    var n = 0;
    anchors.forEach(function (el) {
      el.setAttribute("data-sticky-watch", "w" + n++);
      io.observe(el);
    });
  }

  function initReveal() {
    var targets = document.querySelectorAll(".step, .reveal");
    if (!targets.length) return;

    function showAll() {
      targets.forEach(function (el) {
        el.classList.add("is-in");
      });
    }

    if (prefersReducedMotion()) {
      showAll();
      return;
    }

    if (!("IntersectionObserver" in window)) {
      showAll();
      return;
    }

    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-in");
            io.unobserve(entry.target);
          }
        });
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.12 }
    );

    targets.forEach(function (el) {
      io.observe(el);
    });
  }

  function init() {
    initReady();
    initNav();
    initStickyDl();
    initReveal();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
