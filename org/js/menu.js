(() => {
  var menuButton = document.getElementById("menu-button");
  var menuList = document.getElementById("menu-list");

  menuButton?.addEventListener("click", () => {
    menuList.classList.toggle("!block");
  });

  // close when clicking the overlay backdrop (not the links)
  menuList?.addEventListener("click", (e) => {
    if (e.target === menuList) menuList.classList.remove("!block");
  });
})();
