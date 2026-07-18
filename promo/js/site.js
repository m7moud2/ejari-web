/**
 * Light editorial motion — steps + reveal blocks on scroll.
 * No frameworks. Respects prefers-reduced-motion.
 */
(function () {
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
})();
