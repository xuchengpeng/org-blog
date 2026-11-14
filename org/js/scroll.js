(() => {
  var toplink = document.getElementById("top-link");
  if (!toplink) return;

  var visible = false;

  function update(scrollY) {
    var show = scrollY > 50;
    if (show === visible) return;
    visible = show;
    toplink.style.visibility = show ? "visible" : "hidden";
    toplink.style.opacity = show ? "1" : "0";
  }

  window.addEventListener("scroll", () => update(window.scrollY), { passive: true });
  update(window.scrollY); // handle scroll position restored before load
})();
