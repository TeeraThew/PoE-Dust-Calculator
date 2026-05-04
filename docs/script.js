const REPO = "TeeraThew/PoE-Dust-Calculator";

const RELEASE_API = `https://api.github.com/repos/${REPO}/releases/latest`;
const README_URL = `https://raw.githubusercontent.com/${REPO}/main/README.md`;

const versionEl = document.getElementById("version");
const downloadBtn = document.getElementById("download-btn");
const readmeEl = document.getElementById("readme");

/**
 * Fetch latest release and update UI
 */
async function loadRelease() {
  try {
    const res = await fetch(RELEASE_API);
    if (!res.ok) throw new Error("API failed");

    const data = await res.json();

    // Set version
    versionEl.textContent = data.tag_name || "Latest";

    // Find .exe asset
    const exe = data.assets.find(a => a.name.endsWith(".exe"));

    if (exe) {
      downloadBtn.href = exe.browser_download_url;
    } else {
      // fallback to releases page
      downloadBtn.href = data.html_url;
      downloadBtn.textContent = "View Releases";
    }

  } catch (err) {
    versionEl.textContent = "Unavailable";
    downloadBtn.href = `https://github.com/${REPO}/releases`;
    downloadBtn.textContent = "View Releases";
  }
}

/**
 * Fetch README and render markdown
 */
async function loadReadme() {
  try {
    const res = await fetch(README_URL);
    if (!res.ok) throw new Error("README fetch failed");

    const md = await res.text();

    readmeEl.classList.remove("loading");
    readmeEl.innerHTML = marked.parse(md);

  } catch (err) {
    readmeEl.classList.remove("loading");
    readmeEl.innerHTML = `
      <p>Could not load README.</p>
      <a href="https://github.com/${REPO}#readme" target="_blank">
        View on GitHub
      </a>
    `;
  }
}

// Init
loadRelease();
loadReadme();