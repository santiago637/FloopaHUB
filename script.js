const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q";
const SESSION_KEY = "fh_session";
const SESSION_TTL_MS = 1000 * 60 * 30; // 30 minutos

// Anuncios internos
const internalAds = [
  { type: "image", src: "assets/ad1.png", alt: "Promo" },
  { type: "youtube", src: "https://www.youtube.com/embed/dQw4w9WgXcQ" }
];

// Sesión
function setSession(tag) {
  localStorage.setItem(SESSION_KEY, JSON.stringify({ tag, ts: Date.now() }));
}
function hasValidSession() {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return false;
  const { ts } = JSON.parse(raw);
  return Date.now() - ts < SESSION_TTL_MS;
}
function clearSession() { localStorage.removeItem(SESSION_KEY); }

// Modal helpers
function openModal() { document.getElementById("modal").classList.remove("hidden"); }
function closeModal() { document.getElementById("modal").classList.add("hidden"); }

function renderInternalAd() {
  const adContent = document.getElementById("adContent");
  adContent.innerHTML = "";
  const ad = internalAds[Math.floor(Math.random() * internalAds.length)];
  if (ad.type === "image") {
    adContent.innerHTML = `<img src="${ad.src}" alt="${ad.alt}"/>`;
  } else if (ad.type === "youtube") {
    adContent.innerHTML = `<iframe width="560" height="315" src="${ad.src}" frameborder="0" allowfullscreen></iframe>`;
  }
}

function startCountdownAndRedirect() {
  const countdownEl = document.getElementById("countdown");
  let t = 5;
  countdownEl.textContent = t;
  const iv = setInterval(() => {
    t--;
    countdownEl.textContent = t;
    if (t <= 0) {
      clearInterval(iv);
      window.open(LOOTLABS_LINK, "_blank");
      closeModal();
    }
  }, 1000);
}

// Eventos
document.addEventListener("DOMContentLoaded", () => {
  // Trial Key → anuncio + redirección
  document.getElementById("btnTrial").addEventListener("click", () => {
    setSession("trial");
    renderInternalAd();
    openModal();
    startCountdownAndRedirect();
  });

  // Permanent Key → solo marcar sesión, sin anuncio ni redirección
  document.getElementById("btnPermanent").addEventListener("click", () => {
    setSession("permanent");
    alert("✅ Acceso permanente habilitado. Usa tu key en Roblox.");
  });

  // Botón de saltar anuncio
  document.getElementById("skipBtn").addEventListener("click", () => {
    window.open(LOOTLABS_LINK, "_blank");
    closeModal();
  });

  document.getElementById("modalClose").addEventListener("click", closeModal);
});

// Limpieza de sesión al cerrar
window.addEventListener("beforeunload", clearSession);
