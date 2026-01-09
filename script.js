// Configuración
const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q"; // tu enlace de LootLabs
const SESSION_KEY = "fh_session";
const SESSION_TTL_MS = 1000 * 60 * 30; // 30 minutos
const REDIRECT_DELAY = 5; // segundos

// Anuncios internos (mezcla de imagen y YouTube)
const internalAds = [
  { type: "image", src: "assets/ad1.png", alt: "FloopaHub promo" },
  { type: "youtube", src: "https://www.youtube.com/embed/dQw4w9WgXcQ" },
  { type: "image", src: "assets/ad2.png", alt: "Oferta limitada" },
  { type: "image", src: "assets/ad3.png", alt: "Actualización v2.0" }
];

// Utilidades de sesión
function setSession(tag) {
  localStorage.setItem(SESSION_KEY, JSON.stringify({ tag, ts: Date.now() }));
}
function hasValidSession() {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return false;
  try {
    const { ts } = JSON.parse(raw);
    return Date.now() - ts < SESSION_TTL_MS;
  } catch { return false; }
}
function clearSession() { localStorage.removeItem(SESSION_KEY); }

// Anti-bypass: si entra directo sin sesión, mostrar guardBox y redirigir
function guardAccess() {
  const guardBox = document.getElementById("guardBox");
  if (!hasValidSession()) {
    guardBox.classList.remove("hidden");
    setTimeout(() => { window.location.href = LOOTLABS_LINK; }, 2500);
  } else {
    guardBox.classList.add("hidden");
  }
}

// Modal helpers
function openModal() {
  document.getElementById("modal").classList.remove("hidden");
}
function closeModal() {
  document.getElementById("modal").classList.add("hidden");
  document.getElementById("adContent").innerHTML = "";
}
function renderInternalAd() {
  const adContent = document.getElementById("adContent");
  adContent.innerHTML = "";
  const ad = internalAds[Math.floor(Math.random() * internalAds.length)];
  if (ad.type === "image") {
    const img = document.createElement("img");
    img.src = ad.src; img.alt = ad.alt || "Anuncio";
    adContent.appendChild(img);
  } else if (ad.type === "youtube") {
    const iframe = document.createElement("iframe");
    iframe.width = "560"; iframe.height = "315";
    iframe.src = ad.src; iframe.title = "Video";
    iframe.frameBorder = "0";
    iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
    iframe.allowFullscreen = true;
    adContent.appendChild(iframe);
  }
}

// Countdown y redirección a LootLabs
function startCountdownAndRedirect() {
  const countdownEl = document.getElementById("countdown");
  let t = REDIRECT_DELAY;
  countdownEl.textContent = String(t);
  const iv = setInterval(() => {
    t -= 1;
    countdownEl.textContent = String(t);
    if (t <= 0) {
      clearInterval(iv);
      window.open(LOOTLABS_LINK, "_blank");
      closeModal();
    }
  }, 1000);
}

// Eventos
document.addEventListener("DOMContentLoaded", () => {
  guardAccess();

  document.getElementById("btnTrial").addEventListener("click", () => {
    setSession("trial");
    renderInternalAd();
    openModal();
    startCountdownAndRedirect();
  });

  document.getElementById("btnPermanent").addEventListener("click", () => {
    setSession("permanent");
    renderInternalAd();
    openModal();
    startCountdownAndRedirect();
  });

  document.getElementById("skipBtn").addEventListener("click", () => {
    window.open(LOOTLABS_LINK, "_blank");
    closeModal();
  });

  document.getElementById("modalClose").addEventListener("click", () => {
    closeModal();
  });
});

// Limpieza de sesión al cerrar (opcional)
window.addEventListener("beforeunload", clearSession);
