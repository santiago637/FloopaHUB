import express from "express";
import fetch from "node-fetch";
import crypto from "crypto";

const app = express();
app.use(express.json());

// Configuración PayPal
const PAYPAL_CLIENT = process.env.PAYPAL_CLIENT;
const PAYPAL_SECRET = process.env.PAYPAL_SECRET;
const PAYPAL_API = "https://api-m.sandbox.paypal.com"; // usa sandbox para pruebas

// Crear orden de pago
app.get("/paypal-checkout", async (req, res) => {
  const auth = Buffer.from(`${PAYPAL_CLIENT}:${PAYPAL_SECRET}`).toString("base64");
  const response = await fetch(`${PAYPAL_API}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${auth}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [{ amount: { currency_code: "USD", value: "5.00" } }],
      application_context: {
        return_url: "https://santiago637.github.io/FloopaHUB/?payment=success",
        cancel_url: "https://santiago637.github.io/FloopaHUB/?payment=cancel"
      }
    })
  });
  const data = await response.json();
  res.redirect(data.links.find(l => l.rel === "approve").href);
});

// Validar pago y entregar Permanent Key
app.get("/get-permanent-key", async (req, res) => {
  // Aquí deberías validar el pago con PayPal antes de entregar la key
  const key = crypto.randomBytes(6).toString("hex").match(/.{1,4}/g).join("-");
  res.json({ key });
});

app.listen(3000, () => console.log("Backend en http://localhost:3000"));
