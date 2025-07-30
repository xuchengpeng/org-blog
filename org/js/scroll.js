window.addEventListener("DOMContentLoaded", (_) => {
    scrollTop();
    smartToc();
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
  });
}

function smartToc() {
  var elements = document.querySelectorAll("#table-of-contents a");
  window.addEventListener("scroll", function () {
    if (window.innerWidth < 1024) {
      return;
    }
    if (window.scrollY <= 50) {
      document.querySelectorAll("#table-of-contents a.active").forEach((activeElement) => {
        activeElement.classList.remove("active");
      });
      return;
    }
    elements.forEach((element) => {
      const boundingRect = document.getElementById(element.getAttribute("href").substring(1)).getBoundingClientRect();
      if (boundingRect.top <= 50 && boundingRect.bottom >= 0) {
        document.querySelectorAll("#table-of-contents a.active").forEach((activeElement) => {
          if (activeElement.getAttribute("href") == element.getAttribute("href")) {
            return;
          }
          activeElement.classList.remove("active");
        });
        element.classList.add("active");
      }
    });
  });
}
