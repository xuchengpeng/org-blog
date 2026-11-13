window.addEventListener("DOMContentLoaded", (_) => {
  sidenotes();
});

function sidenotes() {
  document.querySelectorAll(".footref").forEach((ref) => {
    const def = document.getElementById(ref.hash.substring(1));
    const footdef = def && def.closest(".footdef");
    const para = footdef && footdef.querySelector(":scope > .footpara");
    if (!para) {
      return;
    }

    const sidenote = document.createElement("aside");
    sidenote.classList.add("sidenote");
    sidenote.innerHTML = def.innerText + ". " + para.innerHTML;

    (ref.closest("sup") || ref).after(sidenote);
  });
}
