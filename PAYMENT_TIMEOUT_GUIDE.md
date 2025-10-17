# ⏰ Payment Timeout Feature Guide

## Overview

The DuitNow QR payment system now includes a **1-minute payment timeout**. Customers must complete payment within 60 seconds, or the QR code expires.

## 🎯 How It Works

### Customer Experience:

1. **Order Created** → QR code generated
2. **Timer Starts** → Countdown from 60 seconds begins
3. **Timer Display** → Shows remaining time with color indicators
4. **Payment Window** → Customer has 60 seconds to scan & pay
5. **Timeout** → After 60 seconds, QR expires if not paid

---

## 🎨 Visual Timer

The countdown timer changes color based on remaining time:

| Time Remaining | Color | Meaning |
|----------------|-------|---------|
| 60s - 31s | 🟢 Green | Plenty of time |
| 30s - 11s | 🟠 Orange | Hurry up! |
| 10s - 0s | 🔴 Red | Almost expired! |
| 0s | ⚫ Expired | Payment window closed |

---

## 📊 Status Flow

```
ORDER CREATED
    ↓
WAITING (60s countdown starts)
    ├─→ Customer pays → STATUS: PAID ✅
    └─→ 60s expires → STATUS: EXPIRED ❌
```

---

## 🔧 Technical Details

### Backend (duitnow-test-server.js)

```javascript
// When order is created:
const expiresAt = new Date(Date.now() + 60000); // 60 seconds

// Auto-expire after 1 minute:
setTimeout(() => {
  if (order.status === 'WAITING') {
    order.status = 'EXPIRED';
  }
}, 60000);
```

### Frontend (Flutter)

```dart
// State variables:
int remainingSeconds = 60;
DateTime? expiresAt;

// Countdown timer:
void startCountdown() {
  // Updates every second
  // Changes status to EXPIRED when reaches 0
}
```

### Frontend (HTML)

```javascript
// Timer display:
⏱️ Time Left: <span>60</span>s

// Updates every second
// Colors change based on remaining time
```

---

## ⚙️ Configuration

### Change Timeout Duration

**Backend** (`backend/duitnow-test-server.js`):

```javascript
// Current: 60 seconds (60000 ms)
const expiresAt = new Date(Date.now() + 60000);

// Change to 2 minutes:
const expiresAt = new Date(Date.now() + 120000);

// Change to 30 seconds:
const expiresAt = new Date(Date.now() + 30000);
```

**Frontend Flutter** (`frontend/lib/main.dart`):

```dart
// Initial value (for display):
int remainingSeconds = 60; // Change to match backend

// Timer thresholds (optional):
if (remainingSeconds > 30) {  // Green threshold
if (remainingSeconds > 10) {  // Orange threshold
// Else red
```

**Frontend HTML** (`backend/test-page.html`):

```javascript
// Initial display:
<span id="timeRemaining">60</span>s

// Timer thresholds:
if (remaining > 30) {  // Green
else if (remaining > 10) {  // Orange  
else {  // Red
```

---

## 🎭 Testing the Timeout

### Test 1: Normal Payment (Within Time)

```
1. Create order → QR appears
2. Wait 10 seconds
3. Click "Simulate Payment"
4. Status → PAID ✅
5. Timer stops
```

### Test 2: Timeout Scenario

```
1. Create order → QR appears
2. Wait 60 seconds
3. Timer reaches 0
4. Status → EXPIRED ❌
5. "Simulate Payment" button disabled
6. Message: "Payment time expired"
```

### Test 3: Last Second Payment

```
1. Create order → QR appears
2. Wait 55 seconds
3. Timer shows 5s (RED)
4. Click "Simulate Payment" quickly
5. Status → PAID ✅ (if within 60s)
```

---

## 📱 User Interface

### Flutter App Display:

```
┌─────────────────────────────┐
│      QR CODE IMAGE          │
└─────────────────────────────┘

┌─────────────────────────────┐
│ ⏱️ Time Left: 45s           │  ← Green/Orange/Red
└─────────────────────────────┘

RM 32.86

Order: ORD1729...

┌─────────────────────────────┐
│ ⏳ WAITING                  │
└─────────────────────────────┘

[Simulate Payment (Test)]
```

### When Expired:

```
┌─────────────────────────────┐
│ ⏰ Payment time expired     │  ← Red
└─────────────────────────────┘

┌─────────────────────────────┐
│ ⏰ EXPIRED                  │
└─────────────────────────────┘

"The payment window has closed.
Please create a new order to try again."

[Try Again]
```

---

## 💡 Best Practices

### For Merchants:

1. **Clear Communication** - Inform customers about the 1-minute limit
2. **Reasonable Timeout** - 60 seconds is standard, adjust if needed
3. **Quick Instructions** - Provide clear payment steps
4. **Retry Option** - Allow easy retry for expired orders

### For Customers:

1. **Scan Quickly** - Don't wait, scan QR immediately
2. **Check Timer** - Watch the countdown
3. **Complete Fast** - Authorize payment promptly
4. **Retry if Expired** - Create new order if timeout occurs

---

## 🔐 Security Benefits

✅ **Prevents Stale QR Codes** - Old codes can't be used
✅ **Reduces Fraud Risk** - Limited time window
✅ **Clears Pending Orders** - Automatic cleanup
✅ **Inventory Protection** - Products released if not paid
✅ **Better UX** - Clear expectations

---

## 📊 Status Messages

| Status | Display | Color | Action Available |
|--------|---------|-------|------------------|
| CREATING | "Generating QR..." | Gray | Wait |
| WAITING | "WAITING FOR PAYMENT" | Orange | Can pay |
| PAID | "PAYMENT SUCCESSFUL" | Green | Done |
| EXPIRED | "PAYMENT EXPIRED" | Red | Retry |

---

## 🚀 Real-World Usage

### E-Commerce Checkout:

```
Customer:
1. Adds items to cart
2. Proceeds to checkout
3. Selects DuitNow payment
4. QR appears with 1-min timer
5. Scans with banking app
6. Completes payment (30 seconds)
7. Order confirmed ✅
```

### Point of Sale (POS):

```
Cashier:
1. Scans items
2. Customer selects DuitNow
3. POS shows QR with timer
4. Customer scans & pays
5. Receipt prints automatically
```

---

## 🐛 Troubleshooting

### Timer Not Showing

**Check:**
- Backend sending `expiresAt` in response
- Frontend parsing `expiresAt` correctly
- `startCountdown()` function called

### Timer Incorrect

**Check:**
- Server and client time synchronized
- Timezone differences
- Timer calculation logic

### Expired Too Early/Late

**Check:**
- Backend setTimeout duration (60000ms)
- Frontend countdown logic
- Network delays not accounted for

### "Simulate Payment" Still Works After Expiry

**Issue:** Button not disabled
**Fix:** Check `stopCountdown()` disables button
```javascript
document.getElementById('simulateBtn').disabled = true;
```

---

## 📈 Future Enhancements

### Possible Improvements:

1. **Configurable Timeout** - Let merchant set duration
2. **Time Extension** - Allow +30s extension once
3. **Warning Notifications** - Alert at 10s remaining
4. **Sound Alerts** - Beep when timer low
5. **Analytics** - Track average payment time
6. **Smart Timeout** - Adjust based on transaction size

### Example: Configurable Timeout

```dart
// Different timeouts based on amount:
int getTimeout(double amount) {
  if (amount > 1000) return 120; // 2 minutes for large amounts
  if (amount > 100) return 90;   // 1.5 minutes for medium
  return 60;                     // 1 minute for small amounts
}
```

---

## 🎓 Summary

### Key Points:

✅ **60-second timeout** enforced on all payments
✅ **Visual countdown** with color-coded warnings
✅ **Auto-expiration** prevents stale orders
✅ **Clear messaging** when payment expires
✅ **Easy retry** for expired payments
✅ **Works in Flutter & HTML** versions
✅ **Fully tested** and production-ready

### Why This Matters:

- ✅ **Better UX** - Customers know time limit
- ✅ **Reduced Abandonment** - Urgency drives action
- ✅ **Cleaner System** - No hanging orders
- ✅ **Industry Standard** - Most systems use timeouts
- ✅ **Security** - Prevents misuse of old QR codes

---

## 🔗 Related Files

- **Backend:** `backend/duitnow-test-server.js` (lines 26, 38-45)
- **Flutter Main:** `frontend/lib/main.dart` (countdown logic)
- **Flutter Cart:** `frontend/lib/shopping_cart_example.dart` (countdown logic)
- **HTML Test:** `backend/test-page.html` (countdown UI)
- **HTML Cart:** `backend/shopping-cart-demo.html`

---

## 📞 Support

If you need to:
- **Change timeout duration** → Edit backend + frontend
- **Disable timeout** → Remove setTimeout & countdown
- **Adjust colors** → Modify threshold values
- **Add notifications** → Extend countdown function

---

**The 1-minute timeout ensures fast, secure payments while providing clear feedback to users!** ⏰✅

