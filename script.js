// Configuración
const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q"; // tu enlace de LootLabs
const DESTINATION_AFTER_LOOTLABS = "https://santiago637.github.io/FloopaHUB/"; // tu GitHub Pages
const SESSION_KEY = "fh_session";
const SESSION_TTL_MS = 1000 * 60 * 30; // 30 minutos

// Anuncios internos (puedes usar imágenes o videos embebidos)
const internalAds = [
  { type: "image", src: "assets/ad1.png", alt: "Ad 1" },
  { type: "image", src: "assets/ad2.png", alt: "Ad 2" },
  { type: "youtube", src: "https://www.youtube.com/embed/dQw4w9WgXcQ" },
  { type: "image", src: "assets/ad3.png", alt: "Ad 3" }
];

// Utilidades de sesión
function setSession(tag) {
  const payload = { tag, ts: Date.now() };
  localStorage.setItem(SESSION_KEY, JSON.stringify(payload));
}
function hasValidSession() {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return false;
  try {
    const { ts } = JSON.parse(raw);
    return Date.now() - ts < SESSION_TTL_MS;
  } catch {
    return false;
  }
}
function clearSession() {
  localStorage.removeItem(SESSION_KEY);
}

// Anti-bypass: si el usuario entra directo sin sesión, mostrar guardBox y redirigir
function guardAccess() {
  const guardBox = document.getElementById("guardBox");
  if (!hasValidSession()) {
    guardBox.classList.remove("hidden");
    // Redirigir a LootLabs si intenta entrar directo
    setTimeout(() => {
      window.location.href = LOOTLABS_LINK;
    }, 2500);
  }
}

// Render de anuncio interno
function renderInternalAd() {
  const adBox = document.getElementById("adBox");
  const adContent = document.getElementById("adContent");
  adContent.innerHTML = "";
  const ad = internalAds[Math.floor(Math.random() * internalAds.length)];
  if (ad.type === "image") {
    const img = document.createElement("img");
    img.src = ad.src; img.alt = ad.alt || "Ad";
    adContent.appendChild(img);
  } else if (ad.type === "youtube") {
    const iframe = document.createElement("iframe");
    iframe.width = "560"; iframe.height = "315";
    iframe.src = ad.src; iframe.title = "YouTube video";
    iframe.frameBorder = "0";
    iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
    iframe.allowFullscreen = true;
    adContent.appendChild(iframe);
  }
  adBox.classList.remove("hidden");
}

// Countdown y redirección a LootLabs
function startCountdownAndRedirect() {
  const countdownEl = document.getElementById("countdown");
  let t = 5;
  countdownEl.textContent = String(t);
  const iv = setInterval(() => {
    t -= 1;
    countdownEl.textContent = String(t);
    if (t <= 0) {
      clearInterval(iv);
      window.open(LOOTLABS_LINK, "_blank");
    }
  }, 1000);
}

// Eventos
document.addEventListener("DOMContentLoaded", () => {
  guardAccess();

  document.getElementById("btnTrial").addEventListener("click", () => {
    setSession("trial");
    renderInternalAd();
    startCountdownAndRedirect();
  });

  document.getElementById("btnPermanent").addEventListener("click", () => {
    setSession("permanent");
    renderInternalAd();
    startCountdownAndRedirect();
  });

  // Si el usuario vuelve desde LootLabs, refresca sesión y oculta guardBox
  const guardBox = document.getElementById("guardBox");
  if (hasValidSession()) {
    guardBox.classList.add("hidden");
  }
});

// Opcional: al cerrar la pestaña, limpiar sesión para forzar nuevo paso por LootLabs
window.addEventListener("beforeunload", () => {
  clearSession();
});
