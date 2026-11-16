(() => {
  function createCopyButton(highlightDiv) {
    const button = document.createElement("button");
    button.className = "copy-code";
    button.type = "button";
    button.textContent = "Copy";
    let timer;
    button.addEventListener("click", async () => {
      const codeToCopy = highlightDiv.querySelector("pre.src")?.textContent.trim();
      if (!codeToCopy) return;
      try {
        await navigator.clipboard.writeText(codeToCopy);
        button.textContent = "Copied";
      } catch {
        button.textContent = "Failed";
      }
      clearTimeout(timer);
      timer = setTimeout(() => (button.textContent = "Copy"), 2000);
    });
    highlightDiv.appendChild(button);
  }

  document.querySelectorAll(".org-src-container").forEach(createCopyButton);
})();
