const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q&from=lootlabs";
const LINKVERTISE_LINK = "https://linkvertise.com/12345/floopa-key?from=linkvertise";

// Ventana de validez para la verificación en ms (30 minutos)
const VERIFICATION_WINDOW_MS = 30 * 60 * 1000;
const LS_KEY_PENDING = "floopahub_pending_verification";

/* Generar key en formato XXXX-XXXX-XXXX */
function generateKey() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  function block(len) {
    let out = "";
    for (let i = 0; i < len; i++) {
      out += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return out;
  }
  return `${block(4)}-${block(4)}-${block(4)}`;
}

/* LocalStorage helpers */
function markPendingVerification(platform) {
  const payload = { platform, ts: Date.now() };
  try { localStorage.setItem(LS_KEY_PENDING, JSON.stringify(payload)); }
  catch (e) { console.warn("localStorage no disponible", e); }
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
  } catch (e) { console.warn("Error leyendo localStorage", e); return null; }
}
function clearPendingVerification() {
  try { localStorage.removeItem(LS_KEY_PENDING); } catch (e) {}
}

/* UI helpers */
function showElement(id) {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.remove("hidden");
  el.setAttribute("aria-hidden", "false");
}
function hideElement(id) {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.add("hidden");
  el.setAttribute("aria-hidden", "true");
}
function setNote(text) {
  const note = document.getElementById("startNote");
  if (note) note.textContent = text;
}

/* Copiar al portapapeles */
function setupCopyButton() {
  const btn = document.getElementById("btnCopyKey");
  const trialKey = document.getElementById("trialKey");
  if (!btn || !trialKey) return;
  btn.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(trialKey.textContent || "");
      btn.textContent = "Copiado";
      setTimeout(() => (btn.textContent = "Copiar key"), 2000);
    } catch (e) {
      btn.textContent = "Error copiar";
      setTimeout(() => (btn.textContent = "Copiar key"), 2000);
    }
  });
}

/* Botón Hecho vuelve a pantalla inicial limpia */
function setupDoneButton() {
  const btn = document.getElementById("btnDone");
  if (!btn) return;
  btn.addEventListener("click", () => {
    hideElement("trialResult");
    // limpiar cualquier marca pendiente por seguridad
    clearPendingVerification();
    // mostrar pantalla inicial
    showElement("startScreen");
    setNote("La clave se usa dentro de Roblox. Aquí solo guiamos el proceso.");
  });
}

/* Mostrar mensaje de error/instrucción en el área de resultado */
function showVerificationError(message) {
  hideElement("startScreen");
  hideElement("platformChoice");
  showElement("trialResult");
  const trialKey = document.getElementById("trialKey");
  if (trialKey) trialKey.textContent = message || "No se pudo verificar tu visita. Reintenta el proceso.";
}

/* Mostrar la key tras verificación correcta */
function showKeyUI(key) {
  hideElement("startScreen");
  hideElement("platformChoice");
  const trialKey = document.getElementById("trialKey");
  if (trialKey) trialKey.textContent = key;
  showElement("trialResult");
}

/* Inicialización principal */
document.addEventListener("DOMContentLoaded", () => {
  const btnTrial = document.getElementById("btnTrial");
  const btnLinkvertise = document.getElementById("btnLinkvertise");
  const btnLootlabs = document.getElementById("btnLootlabs");

  if (!btnTrial) return;

  // 1) Al pulsar Trial Key mostrar opciones
  btnTrial.addEventListener("click", () => {
    hideElement("startScreen");
    showElement("platformChoice");
    // mensaje contextual
    const pendingNote = document.getElementById("pendingNote");
    if (pendingNote) pendingNote.hidden = true;
  });

  // 2) Al elegir plataforma marcar y redirigir
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

  // 3) Al volver comprobar parámetros URL y validar con localStorage
  const params = new URLSearchParams(window.location.search);
  const from = params.get("from"); // 'lootlabs' o 'linkvertise'

  if (from === "lootlabs" || from === "linkvertise") {
    const pending = readPendingVerification();

    if (!pending) {
      showVerificationError("No se detectó una verificación previa o expiró. Vuelve a pulsar 'Obtener Trial Key' y completa el proceso en la plataforma.");
      return;
    }
    if (pending.expired) {
      showVerificationError("La verificación expiró. Solicita la Trial Key de nuevo y completa el proceso en la plataforma.");
      return;
    }
    if (pending.platform !== from) {
      showVerificationError("La plataforma detectada no coincide con la que iniciaste. Asegúrate de volver desde la misma plataforma.");
      return;
    }

    // OK: generar key, limpiar estado y mostrar
    const key = generateKey();
    clearPendingVerification();
    showKeyUI(key);
    setupCopyButton();
    setupDoneButton();
    return;
  }

  // 4) Si hay una marca pendiente pero no hay 'from' en URL, mostrar instrucción
  const pending = readPendingVerification();
  if (pending && !pending.expired) {
    hideElement("startScreen");
    showElement("platformChoice");
    const pendingNote = document.getElementById("pendingNote");
    if (pendingNote) {
      pendingNote.hidden = false;
      pendingNote.textContent = `Has iniciado el proceso en ${pending.platform}. Completa la verificación en esa plataforma y vuelve aquí.`;
    }
  }

  // Inicializar botones auxiliares si la key ya estuviera presente
  setupCopyButton();
  setupDoneButton();
});
