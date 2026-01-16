const LOOTLABS_LINK = "https://loot-link.com/s?uiZqdVNl";
const LINKVERTISE_LINK = "https://linkvertise.com/12345/floopa-key?from=linkvertise";

const VERIFICATION_WINDOW_MS = 30 * 60 * 1000; // 30 minutos
const LS_KEY_PENDING = "floopahub_pending_verification";

/* Generador seguro de key (cliente-side, no sustituye validación backend) */
function generateKey() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"; // sin ambigüedades
  const block = (n) => Array.from({length:n}, () => chars[Math.floor(Math.random()*chars.length)]).join('');
  return `${block(4)}-${block(4)}-${block(4)}`;
}

/* localStorage helpers */
function markPendingVerification(platform) {
  try {
    localStorage.setItem(LS_KEY_PENDING, JSON.stringify({ platform, ts: Date.now() }));
  } catch (e) {
    console.warn("localStorage no disponible", e);
  }
}
function readPendingVerification() {
  try {
    const raw = localStorage.getItem(LS_KEY_PENDING);
    if (!raw) return null;
    const obj = JSON.parse(raw);
    if (!obj.platform || !obj.ts) return null;
    if (Date.now() - obj.ts > VERIFICATION_WINDOW_MS) {
      localStorage.removeItem(LS_KEY_PENDING);
      return { expired: true };
    }
    return obj;
  } catch (e) {
    console.warn("Error leyendo localStorage", e);
    return null;
  }
}
function clearPendingVerification() {
  try { localStorage.removeItem(LS_KEY_PENDING); } catch (e) {}
}

/* UI helpers */
const show = id => {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.remove("hidden");
  el.setAttribute("aria-hidden", "false");
};
const hide = id => {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.add("hidden");
  el.setAttribute("aria-hidden", "true");
};

/* Copiar al portapapeles */
function setupCopyButton() {
  const btn = document.getElementById("btnCopyKey");
  const trialKey = document.getElementById("trialKey");
  if (!btn || !trialKey) return;
  btn.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(trialKey.textContent || "");
      btn.textContent = "Copiado";
      setTimeout(() => (btn.textContent = "Copiar key"), 1800);
    } catch (e) {
      btn.textContent = "Error copiar";
      setTimeout(() => (btn.textContent = "Copiar key"), 1800);
    }
  });
}

/* Botón Hecho */
function setupDoneButton() {
  const btn = document.getElementById("btnDone");
  if (!btn) return;
  btn.addEventListener("click", () => {
    hide("trialResult");
    clearPendingVerification();
    show("startScreen");
    const note = document.getElementById("startNote");
    if (note) note.textContent = "La clave se usa dentro de Roblox. Aquí solo guiamos el proceso.";
  });
}

/* Mostrar mensaje de error/instrucción en área de resultado */
function showVerificationError(message) {
  hide("startScreen");
  hide("platformChoice");
  show("trialResult");
  const trialKey = document.getElementById("trialKey");
  if (trialKey) trialKey.textContent = message || "No se pudo verificar tu visita. Reintenta el proceso.";
}

/* Mostrar la key tras verificación correcta */
function showKeyUI(key) {
  hide("startScreen");
  hide("platformChoice");
  const trialKey = document.getElementById("trialKey");
  if (trialKey) trialKey.textContent = key;
  show("trialResult");
}

/* Inicialización */
document.addEventListener("DOMContentLoaded", () => {
  const btnTrial = document.getElementById("btnTrial");
  const btnLinkvertise = document.getElementById("btnLinkvertise");
  const btnLootlabs = document.getElementById("btnLootlabs");

  if (!btnTrial) return;

  // Mostrar opciones SOLO cuando el usuario pulsa el botón
  btnTrial.addEventListener("click", () => {
    hide("startScreen");
    show("platformChoice");
    const pendingNote = document.getElementById("pendingNote");
    if (pendingNote) pendingNote.hidden = true;
  });

  // Elegir plataforma: marcar y redirigir
  if (btnLinkvertise) {
    btnLinkvertise.addEventListener("click", (e) => {
      e.preventDefault();
      markPendingVerification("linkvertise");
      window.location.href = LINKVERTISE_LINK;
    });
  }
  if (btnLootlabs) {
    btnLootlabs.addEventListener("click", (e) => {
      e.preventDefault();
      markPendingVerification("lootlabs");
      window.location.href = LOOTLABS_LINK;
    });
  }

  // Al volver: procesar solo si hay ?from=lootlabs o ?from=linkvertise
  const params = new URLSearchParams(window.location.search);
  const from = params.get("from");

  if (from === "lootlabs" || from === "linkvertise") {
    const pending = readPendingVerification();

    if (!pending) {
      showVerificationError("No se detectó una verificación previa o expiró. Vuelve a pulsar 'Obtener Trial Key' y completa el proceso.");
      return;
    }
    if (pending.expired) {
      showVerificationError("La verificación expiró. Solicita la Trial Key de nuevo y completa el proceso.");
      return;
    }
    if (pending.platform !== from) {
      showVerificationError("La plataforma detectada no coincide con la que iniciaste. Asegúrate de volver desde la misma plataforma.");
      return;
    }

    // Todo OK: generar key, limpiar estado y mostrar
    const key = generateKey();
    clearPendingVerification();
    showKeyUI(key);
    setupCopyButton();
    setupDoneButton();
    return;
  }

  // Si hay marca pendiente pero NO hay 'from' en URL, no mostrar elección automáticamente.
  const pending = readPendingVerification();
  if (pending && !pending.expired) {
    const note = document.getElementById("startNote");
    if (note) note.textContent = `Has iniciado el proceso en ${pending.platform}. Completa la verificación en esa plataforma y vuelve aquí.`;
  }

  // Inicializar botones auxiliares
  setupCopyButton();
  setupDoneButton();
});
