async function copyCodeToClipboard(button, highlightDiv) {
  const codeToCopy = highlightDiv.querySelector("pre.src").textContent;
  await navigator.clipboard.writeText(codeToCopy);
  button.innerText = "Copied";
  setTimeout(function () {
    button.innerText = "Copy";
  }, 2000);
}

function createCopyButton(highlightDiv) {
  const button = document.createElement("button");
  button.className = "copy-code";
  button.type = "button";
  button.ariaLabel = "Copy";
  button.innerText = "Copy";
  button.addEventListener("click", () => copyCodeToClipboard(button, highlightDiv));
  highlightDiv.appendChild(button);
}

window.addEventListener("DOMContentLoaded", (_) => {
  document.querySelectorAll(".org-src-container").forEach((highlightDiv) => createCopyButton(highlightDiv));
});
