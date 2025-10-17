import QRCode from "qrcode";

// Simple CRC helper
function crc16ccitt(data) {
  let crc = 0xffff;
  for (let i = 0; i < data.length; i++) {
    crc ^= data.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      if ((crc & 0x8000) !== 0) crc = ((crc << 1) ^ 0x1021) & 0xffff;
      else crc = (crc << 1) & 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, "0");
}

function buildPayload({ orderId, amount }) {
  const base =
    "00020101021226580016A000000677010111011393765009876543210520400005303458" +
    `5406${amount.toFixed(2)}5802MY59Your Store6008KUALALUMPUR621005${orderId}`;
  const crc = crc16ccitt(base + "6304");
  return base + "6304" + crc;
}

export async function createDuitNowQR(orderId, amount) {
  const payload = buildPayload({ orderId, amount });
  const qr = await QRCode.toDataURL(payload, { errorCorrectionLevel: "M" });
  return { payload, qr };
}

// Simulate DuitNow calling back the backend after payment
export async function simulatePaymentCallback(orderId, backendUrl) {
  console.log("🎭 Simulating DuitNow callback in 7 seconds...");
  setTimeout(async () => {
    try {
      // Use dynamic import for node-fetch if native fetch is not available
      const fetchFn = globalThis.fetch || (await import('node-fetch')).default;
      
      const response = await fetchFn(`${backendUrl}/api/payment-callback`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ orderId, status: "PAID" }),
      });
      
      if (response.ok) {
        console.log(`✅ Payment callback successful for order ${orderId}`);
      } else {
        console.log(`⚠️ Payment callback failed: ${response.status}`);
      }
    } catch (error) {
      console.error(`❌ Payment callback error:`, error.message);
    }
  }, 7000); // simulate 7 sec delay
}