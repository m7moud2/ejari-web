/**
 * Promo chrome: sticky nav solidify on scroll, mobile menu, editorial reveals.
 * No frameworks. Respects prefers-reduced-motion.
 */
(function () {
  function initNav() {
    var header = document.querySelector("[data-site-nav]");
    if (!header) return;

    var toggle = header.querySelector("[data-nav-toggle]");
    var links = header.querySelector(".nav-links");

    function setSolid() {
      var solid = window.scrollY > 18 || header.classList.contains("is-open");
      header.classList.toggle("is-solid", solid);
    }

    function setOpen(open) {
      header.classList.toggle("is-open", open);
      document.body.classList.toggle("is-nav-open", open);
      if (toggle) {
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
        var key = open ? "nav.menuClose" : "nav.menuOpen";
        var label =
          window.EjariI18n && window.EjariI18n.t
            ? window.EjariI18n.t(key, window.EjariI18n.getLang())
            : null;
        if (label) toggle.setAttribute("aria-label", label);
      }
      setSolid();
    }

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
      if (e.key === "Escape") setOpen(false);
    });

    window.addEventListener("resize", function () {
      if (window.matchMedia("(min-width: 861px)").matches) setOpen(false);
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

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
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
    initNav();
    initReveal();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
