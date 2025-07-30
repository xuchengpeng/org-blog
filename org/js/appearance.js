const userPreference = localStorage.getItem("appearance");
if (userPreference === "dark") {
  document.documentElement.classList.add("dark");
}

window.addEventListener("DOMContentLoaded", (_) => {
  document.getElementById("appearance-switcher").addEventListener("click", () => {
    document.documentElement.classList.toggle("dark");
    var targetAppearance = document.documentElement.classList.contains("dark") ? "dark" : "light";
    localStorage.setItem("appearance", targetAppearance);
  });
});
