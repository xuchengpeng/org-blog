(() => {
  document.querySelectorAll(".footref").forEach((ref) => {
    const def = document.getElementById(ref.hash.substring(1));
    const para = def?.closest(".footdef")?.querySelector(":scope > .footpara");
    if (!para) return;

    const sidenote = document.createElement("span");
    sidenote.classList.add("sidenote");
    sidenote.setAttribute("role", "note");
    sidenote.textContent = def.textContent + ". ";
    sidenote.append(para.cloneNode(true));

    (ref.closest("sup") || ref).after(sidenote);
  });
})();
