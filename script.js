document.getElementById("getKey").addEventListener("click", () => {
  // Redirigir a LootLabs
  window.open("https://loot-link.com/s?bwxRK29Q", "_blank");
  document.getElementById("keyBox").classList.remove("hidden");
});

document.getElementById("validateKey").addEventListener("click", async () => {
  const key = document.getElementById("keyInput").value;
  const user = "webUser"; // opcional: puedes pedir username real

  if (!key) {
    return showMessage("Introduce una key primero.");
  }

  try {
    const res = await fetch(`https://TU-SERVIDOR-RENDER.onrender.com/validate?key=${key}&user=${user}`);
    const data = await res.json();

    if (data.ok) {
      switch (data.tier) {
        case "trial":
          showMessage("✅ Key válida. Trial de 24h activado.");
          break;
        case "permanent":
          showMessage("✅ Acceso Lifetime activado.");
          break;
        case "vip":
          showMessage("✅ Acceso VIP activado.");
          break;
        default:
          showMessage("⚠️ Key válida, pero tipo desconocido.");
      }
    } else {
      showMessage("❌ Key inválida o expirada.");
    }
  } catch (err) {
    showMessage("❌ Error al validar la key.");
  }
});

function showMessage(msg) {
  document.getElementById("message").innerText = msg;
}
