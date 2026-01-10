const LOOTLABS_LINK = "https://loot-link.com/s?bwxRK29Q";
const PAYPAL_CHECKOUT = "https://tu-backend.com/paypal-checkout"; // URL de tu backend

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
  const btnPermanent = document.getElementById("btnPermanent");

  // Trial Key → redirige a LootLabs
  btnTrial.addEventListener("click", () => {
    window.location.href = LOOTLABS_LINK;
  });

  // Permanent Key → redirige a PayPal checkout
  btnPermanent.addEventListener("click", () => {
    window.location.href = PAYPAL_CHECKOUT;
  });

  // Detectar si LootLabs devolvió al usuario
  const params = new URLSearchParams(window.location.search);
  if (params.get("from") === "lootlabs") {
    const key = generateKey();
    document.getElementById("trialKey").textContent = key;
    document.getElementById("trialResult").classList.remove("hidden");
  }

  // Detectar si PayPal devolvió al usuario con pago confirmado
  if (params.get("payment") === "success") {
    fetch("https://tu-backend.com/get-permanent-key")
      .then(res => res.json())
      .then(data => {
        document.getElementById("permKey").textContent = data.key;
        document.getElementById("permResult").classList.remove("hidden");
      })
      .catch(() => {
        document.getElementById("permResult").classList.remove("hidden");
        document.getElementById("permKey").textContent = "❌ Error al validar el pago.";
      });
  }
});
