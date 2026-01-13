const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q";

// Generar key en formato xxxx-xxxx-xxxx
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

document.addEventListener("DOMContentLoaded", () => {
  const btnTrial = document.getElementById("btnTrial");

  // Trial Key → redirige a LootLabs
  btnTrial.addEventListener("click", () => {
    window.location.href = LOOTLABS_LINK;
  });

  // Detectar si LootLabs devolvió al usuario
  const params = new URLSearchParams(window.location.search);
  if (params.get("from") === "lootlabs") {
    const key = generateKey();
    document.getElementById("trialKey").textContent = key;
    document.getElementById("trialResult").classList.remove("hidden");
  }
});
