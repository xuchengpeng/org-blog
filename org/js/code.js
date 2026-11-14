(() => {
  function createCopyButton(highlightDiv) {
    const button = document.createElement("button");
    button.className = "copy-code";
    button.type = "button";
    button.innerText = "Copy";
    let timer;
    button.addEventListener("click", async () => {
      const codeToCopy = highlightDiv.querySelector("pre.src")?.textContent.trim();
      if (!codeToCopy) return;
      try {
        await navigator.clipboard.writeText(codeToCopy);
        button.innerText = "Copied";
      } catch {
        button.innerText = "Failed";
      }
      clearTimeout(timer);
      timer = setTimeout(() => (button.innerText = "Copy"), 2000);
    });
    highlightDiv.appendChild(button);
  }

  document.querySelectorAll(".org-src-container").forEach(createCopyButton);
})();
