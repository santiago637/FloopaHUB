const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q&from=lootlabs";
const LINKVERTISE_LINK = "https://linkvertise.com/12345/floopa-key?from=linkvertise";

// Tiempo máximo válido para la verificación (ms). Aquí 30 minutos.
const VERIFICATION_WINDOW_MS = 30 * 60 * 1000;

// Clave de localStorage para marcar la verificación pendiente
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

/* Guardar en localStorage la plataforma elegida y la hora */
function markPendingVerification(platform) {
  const payload = {
    platform,
    ts: Date.now()
  };
  try {
    localStorage.setItem(LS_KEY_PENDING, JSON.stringify(payload));
  } catch (e) {
    console.warn("No se pudo guardar el estado en localStorage", e);
  }
}

/* Leer y validar la marca de verificación */
function readPendingVerification() {
  try {
    const raw = localStorage.getItem(LS_KEY_PENDING);
    if (!raw) return null;
    const obj = JSON.parse(raw);
    if (!obj.platform || !obj.ts) return null;
    // comprobar ventana de tiempo
    if (Date.now() - obj.ts > VERIFICATION_WINDOW_MS) {
      // expiró
      localStorage.removeItem(LS_KEY_PENDING);
      return { expired: true };
    }
    return obj;
  } catch (e) {
    console.warn("Error leyendo localStorage", e);
    return null;
  }
}

/* Limpiar la marca pendiente */
function clearPendingVerification() {
  try {
    localStorage.removeItem(LS_KEY_PENDING);
  } catch (e) {
    // ignore
  }
}

/* Mostrar la key en la UI */
function showKeyUI(key) {
  const platformChoice = document.getElementById("platformChoice");
  const startScreen = document.getElementById("startScreen");
  const trialResult = document.getElementById("trialResult");
  const trialKey = document.getElementById("trialKey");

  if (startScreen) startScreen.classList.add("hidden");
  if (platformChoice) platformChoice.classList.add("hidden");

  if (trialKey) trialKey.textContent = key;
  if (trialResult) trialResult.classList.remove("hidden");
}

/* Mostrar mensaje de error / instrucciones si la verificación falla */
function showVerificationError(message) {
  const platformChoice = document.getElementById("platformChoice");
  const startScreen = document.getElementById("startScreen");
  const trialResult = document.getElementById("trialResult");

  if (startScreen) startScreen.classList.add("hidden");
  if (platformChoice) platformChoice.classList.add("hidden");
  if (trialResult) trialResult.classList.remove("hidden");

  const trialKey = document.getElementById("trialKey");
  if (trialKey) {
    trialKey.textContent = message || "No se pudo verificar tu visita. Intenta volver desde la plataforma o pulsa 'Obtener Trial Key' de nuevo.";
  }
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

/* Manejo principal al cargar la página */
document.addEventListener("DOMContentLoaded", () => {
  const btnTrial = document.getElementById("btnTrial");
  const platformChoice = document.getElementById("platformChoice");
  const btnLinkvertise = document.getElementById("btnLinkvertise");
  const btnLootlabs = document.getElementById("btnLootlabs");

  // Si el HTML no tiene las secciones esperadas, no hacer nada
  if (!btnTrial) return;

  // 1) Mostrar opciones al presionar Trial Key
  btnTrial.addEventListener("click", () => {
    // mostrar la sección de elección y ocultar la pantalla inicial si existe
    if (platformChoice) platformChoice.classList.remove("hidden");
    const startScreen = document.getElementById("startScreen");
    if (startScreen) startScreen.classList.add("hidden");
  });

  // 2) Redirecciones: antes de redirigir, marcar la plataforma elegida
  if (btnLinkvertise) {
    btnLinkvertise.addEventListener("click", (e) => {
      e.preventDefault();
      markPendingVerification("linkvertise");
      // redirigir
      window.location.href = LINKVERTISE_LINK;
    });
  }
  if (btnLootlabs) {
    btnLootlabs.addEventListener("click", (e) => {
      e.preventDefault();
      markPendingVerification("lootlabs");
      // redirigir
      window.location.href = LOOTLABS_LINK;
    });
  }

  // 3) Al volver: comprobar parámetros en la URL y validar con localStorage
  const params = new URLSearchParams(window.location.search);
  const from = params.get("from"); // esperamos 'lootlabs' o 'linkvertise'

  if (from === "lootlabs" || from === "linkvertise") {
    const pending = readPendingVerification();

    // Caso: no hay marca pendiente (p. ej. abrió la URL en otra máquina o expiró)
    if (!pending) {
      showVerificationError("No se detectó una verificación previa o la verificación expiró. Vuelve a pulsar 'Obtener Trial Key' y completa el proceso en la plataforma.");
      return;
    }

    // Caso: expirado
    if (pending.expired) {
      showVerificationError("La verificación expiró. Vuelve a solicitar la Trial Key y completa el proceso en la plataforma.");
      return;
    }

    // Caso: la plataforma registrada no coincide con el parámetro 'from'
    if (pending.platform !== from) {
      showVerificationError("La plataforma detectada no coincide con la que iniciaste. Asegúrate de volver desde la misma plataforma que elegiste.");
      return;
    }

    // Si todo OK: generar y mostrar la key, limpiar la marca pendiente
    const key = generateKey();
    clearPendingVerification();
    showKeyUI(key);
    setupCopyButton();
    return;
  }

  // 4) Si no hay parámetro 'from' y hay una marca pendiente, mostrar instrucción para volver
  const pending = readPendingVerification();
  if (pending && !pending.expired) {
    // Mostrar la pantalla de elección oculta y una nota para que el usuario complete la verificación
    if (platformChoice) platformChoice.classList.remove("hidden");
    // Opcional: mostrar un mensaje breve en la UI (si tienes un elemento para mensajes)
    const noteEl = document.querySelector(".note");
    if (noteEl) {
      noteEl.textContent = `Has iniciado el proceso en ${pending.platform}. Completa la verificación en esa plataforma y vuelve aquí para recibir tu key.`;
    }
  }

  // Inicializar botón copiar si la key ya está presente por alguna razón
  setupCopyButton();
});
