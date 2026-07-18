/**
 * Light page motion — steps reveal on scroll.
 * No frameworks.
 */
(function () {
  var steps = document.querySelectorAll(".step");
  if (!steps.length) return;

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    steps.forEach(function (el) {
      el.classList.add("is-in");
    });
    return;
  }

  if (!("IntersectionObserver" in window)) {
    steps.forEach(function (el) {
      el.classList.add("is-in");
    });
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
    { rootMargin: "0px 0px -8% 0px", threshold: 0.15 }
  );

  steps.forEach(function (el) {
    io.observe(el);
  });
})();
