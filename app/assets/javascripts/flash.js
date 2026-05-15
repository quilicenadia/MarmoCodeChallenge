// Fade out and remove flash banners after a short delay so they don't pollute the layout.
(function () {
  function dismissFlashes() {
    document.querySelectorAll(".flash").forEach(function (el) {
      setTimeout(function () {
        el.style.transition = "opacity 0.4s";
        el.style.opacity = "0";
        setTimeout(function () { el.remove(); }, 400);
      }, 3000);
    });
  }

  document.addEventListener("turbolinks:load", dismissFlashes);
  document.addEventListener("DOMContentLoaded", dismissFlashes);
})();
