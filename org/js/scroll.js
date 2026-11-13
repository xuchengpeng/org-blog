window.addEventListener("DOMContentLoaded", (_) => {
  scrollTop();
});

function scrollTop() {
  var toplink = document.getElementById("top-link");
  window.addEventListener("scroll", () => {
    if (document.body.scrollTop > 50 || document.documentElement.scrollTop > 50) {
      toplink.style.visibility = "visible";
      toplink.style.opacity = "1";
    } else {
      toplink.style.visibility = "hidden";
      toplink.style.opacity = "0";
    }
  }, { passive: true });
}
