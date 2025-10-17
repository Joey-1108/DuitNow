# 🛒 Shopping Cart - Automatic QR Payment Guide

## What This Does

Instead of clicking preset amounts (RM 25.50, RM 100.00), the system now **automatically calculates** your cart total and generates a QR code with the exact amount!

## ✨ How It Works

### Customer Flow:

1. **Browse Products** → Add items to cart
2. **View Cart** → See all items and total
3. **Click "Pay Now"** → **QR code generates automatically!**
4. **Scan & Pay** → Complete payment
5. **Status Updates** → See PAID confirmation

**No manual amount selection needed!** 🎉

---

## 🚀 How to Test

### Option 1: Flutter App (Mobile Experience)

```bash
# Make sure backend is running first
node backend/duitnow-test-server.js

# In another terminal:
cd frontend
flutter run -d chrome
```

Then:
1. Click **"Shopping Cart Demo"** button (green button)
2. See sample cart with Coffee, Sandwich, Cake
3. Adjust quantities with +/− buttons
4. Watch total update automatically
5. Click **"Pay Now with DuitNow QR"**
6. QR code appears with exact total!
7. Click **"Simulate Payment"** to test

### Option 2: Browser (Quick Test)

1. Make sure backend is running
2. Open: `backend/shopping-cart-demo.html`
3. Adjust item quantities
4. Click "Pay Now with DuitNow QR"
5. QR code appears automatically!
6. Simulate payment to test

---

## 💡 Real-World Integration Example

### In Your E-Commerce App:

```dart
// When customer completes checkout
double cartTotal = calculateCartTotal(); // e.g., RM 45.80

// Navigate to payment - QR generates automatically!
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AutoPaymentPage(
      amount: cartTotal,
      items: cartItems,
    ),
  ),
);

// That's it! No manual amount entry needed.
```

### The backend receives:

```json
POST /api/create-order
{
  "amount": 45.80
}
```

Backend automatically:
- Creates order with unique ID
- Generates QR code with exact amount
- Returns QR image
- Tracks payment status

---

## 📊 Example Scenarios

### Scenario 1: Coffee Shop

```
Cart:
- 2x Coffee @ RM 5.50    = RM 11.00
- 1x Sandwich @ RM 12.00 = RM 12.00
- 1x Cake @ RM 8.00      = RM 8.00
                Subtotal = RM 31.00
            Tax (6%)     = RM  1.86
                 TOTAL   = RM 32.86  ← This goes to QR code!
```

**QR code automatically shows RM 32.86** ✅

### Scenario 2: Online Store

```
Cart:
- 1x T-Shirt @ RM 29.90     = RM 29.90
- 2x Socks @ RM 9.90        = RM 19.80
- Shipping                  = RM  5.00
                   Subtotal = RM 54.70
                Tax (6%)    = RM  3.28
                    TOTAL   = RM 57.98  ← Auto QR!
```

**QR code automatically shows RM 57.98** ✅

---

## 🔧 Customization Options

### 1. Add Your Own Products

Edit `frontend/lib/shopping_cart_example.dart`:

```dart
final List<CartItem> cartItems = [
  CartItem(name: 'Your Product', price: 19.90, quantity: 1),
  CartItem(name: 'Another Product', price: 25.00, quantity: 2),
  // Add more items...
];
```

### 2. Change Tax Rate

```dart
// Current: 6%
'Service Tax (6%):', 
Text('RM ${(cartTotal * 0.06).toFixed(2)}')

// Change to 8%:
'Service Tax (8%):', 
Text('RM ${(cartTotal * 0.08).toFixed(2)}')
```

### 3. Add Discount Codes

```dart
double discount = 0.0;
if (hasPromoCode) {
  discount = cartTotal * 0.10; // 10% off
}
final total = (cartTotal - discount) * 1.06; // After discount, then tax
```

### 4. Add Shipping Fee

```dart
const shippingFee = 5.00;
final total = (cartTotal + shippingFee) * 1.06;
```

---

## 🎯 Key Features

✅ **Automatic Calculation** - No manual entry
✅ **Real-time Updates** - Cart total updates as you change quantities
✅ **Tax Included** - Automatically calculates service tax
✅ **Order Summary** - Shows what customer is paying for
✅ **Instant QR** - Generates immediately on checkout
✅ **Any Amount** - Backend supports any value (0.01 to 999999.99)
✅ **Order Tracking** - Each payment has unique ID

---

## 📱 UI Flow

```
Shopping Cart Screen
├── Item 1: Coffee (2x)    RM 11.00
├── Item 2: Sandwich       RM 12.00
├── Item 3: Cake           RM  8.00
├── ─────────────────────
├── Subtotal:              RM 31.00
├── Tax (6%):              RM  1.86
├── TOTAL:                 RM 32.86
└── [Pay Now Button] ─────────┐
                               │
                               ↓
                    Payment Screen
                    ├── Order Summary (items)
                    ├── QR Code (auto-generated)
                    ├── Amount: RM 32.86
                    ├── Status: WAITING
                    ├── [Simulate Payment]
                    └── [Back to Cart]
```

---

## 🔌 Backend API

The backend **already supports any amount**! No changes needed.

### Create Order Endpoint

```bash
POST http://localhost:3000/api/create-order
Content-Type: application/json

{
  "amount": 32.86  // Any amount works!
}
```

### Response

```json
{
  "orderId": "ORD1729180123456",
  "amount": 32.86,
  "qr": "data:image/png;base64,iVBORw0KG...",
  "status": "WAITING"
}
```

---

## 🎨 Screenshots Flow

### 1. Shopping Cart
- Shows items with quantities
- +/− buttons to adjust
- Live total calculation
- Green "Pay Now" button

### 2. Payment Screen
- Order summary at top
- Large QR code in center
- Amount prominently displayed
- Order ID for tracking
- Status badge (WAITING/PAID)
- Simulate button for testing

### 3. Success State
- Green checkmark
- "PAYMENT SUCCESSFUL"
- Back to home option

---

## 💻 Code Examples

### Integrate with Your App

```dart
// In your checkout page:
import 'shopping_cart_example.dart';

// When ready to pay:
final total = cart.calculateTotal();

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AutoPaymentPage(
      amount: total,
      items: cart.items,
    ),
  ),
);
```

### Custom Payment Widget

```dart
// Create payment with any amount
void payWithDuitNow(double amount) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/api/create-order'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'amount': amount}),
  );
  
  final data = jsonDecode(response.body);
  // Show QR: data['qr']
  // Track order: data['orderId']
}
```

---

## 🚦 Testing Checklist

- [ ] Cart displays items correctly
- [ ] Quantities can be changed
- [ ] Total updates in real-time
- [ ] Tax calculation is correct
- [ ] "Pay Now" navigates to payment
- [ ] QR code generates automatically
- [ ] Correct amount shown
- [ ] Order ID is unique
- [ ] Status polling works
- [ ] Simulate payment changes status to PAID
- [ ] Can return to cart and start over

---

## 🎓 Benefits Over Fixed Amounts

| Fixed Amounts | Automatic Cart |
|---------------|----------------|
| ❌ Click "Pay RM 25.50" | ✅ Cart calculates total |
| ❌ Limited to preset values | ✅ Any amount works |
| ❌ Not realistic for e-commerce | ✅ Real shopping experience |
| ❌ Manual amount entry | ✅ Automatic calculation |
| ❌ No item breakdown | ✅ See what you're paying for |

---

## 📈 Next Steps

1. **Test the Demo** - Try both Flutter and browser versions
2. **Add Real Products** - Replace sample items with your products
3. **Integrate with Backend** - Connect to your product database
4. **Add Features**:
   - Product images
   - Remove item from cart
   - Save cart for later
   - Multiple payment methods
   - Order history

---

## ❓ FAQ

**Q: Can I use decimal amounts?**
A: Yes! Any amount like RM 15.75, RM 0.50, RM 999.99 works.

**Q: Does the backend need changes?**
A: No! It already accepts any amount via the `/api/create-order` endpoint.

**Q: Can I add more items?**
A: Yes! Just add more `CartItem` objects to the list.

**Q: How do I change tax rate?**
A: Search for `0.06` (6%) and change to your rate (e.g., `0.08` for 8%).

**Q: Can I remove the tax?**
A: Yes, change `cartTotal * 1.06` to just `cartTotal`.

**Q: Does this work on real phones?**
A: Yes! Use your computer's IP address in the backend URL.

---

## 🎉 Summary

You now have a **complete shopping cart → automatic QR payment flow**!

**Before**: Customer clicks "Pay RM 25.50"
**Now**: Customer adds items → Total calculates → QR generates automatically!

Much more realistic for real-world e-commerce! 🚀

---

**Happy Coding!** 🛒💳✨

