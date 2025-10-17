# 🚀 Quick Start Guide - DuitNow QR Payment Testing

Get up and running in 3 easy steps!

## Prerequisites

- ✅ Node.js installed
- ✅ Flutter SDK installed  
- ✅ A web browser or mobile emulator

## Step 1: Install Dependencies

```bash
npm install
```

## Step 2: Start Backend Server

### Option A: Using Batch File (Windows)
```bash
START_BACKEND.bat
```

### Option B: Using npm
```bash
npm start
```

### Option C: Direct Node Command
```bash
node backend/duitnow-test-server.js
```

You should see:
```
🚀 DuitNow Test Server running on http://localhost:3000

📱 Available endpoints:
   POST   /api/create-order        - Create new payment order
   GET    /api/order/:orderId      - Get order status
   POST   /api/simulate-payment    - Simulate payment (testing)
   GET    /api/orders              - List all orders
   GET    /health                  - Health check

💡 Ready to test DuitNow QR payments!
```

## Step 3: Choose Your Testing Method

### Method 1: Web Browser Test (Easiest) ✨

1. Keep backend server running
2. Open `backend/test-page.html` in your browser
3. Click any amount button
4. See QR code generated
5. Click "Simulate Payment" button
6. Watch status change to PAID!

### Method 2: Flutter Mobile App (Recommended) 📱

#### Option A: Using Batch File (Windows)
```bash
START_FLUTTER.bat
```

#### Option B: Manual Commands
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

For Android emulator:
```bash
cd frontend
flutter pub get
flutter emulator --launch <emulator_name>
flutter run
```

### Method 3: API Testing (For Developers) 🛠️

#### Option A: Using Test Script
```bash
TEST_API.bat
```

#### Option B: Manual curl Commands
```bash
# Create order
curl -X POST http://localhost:3000/api/create-order \
  -H "Content-Type: application/json" \
  -d "{\"amount\": 25.50}"

# Check status
curl http://localhost:3000/api/order/ORD1234567890123

# Simulate payment
curl -X POST http://localhost:3000/api/simulate-payment \
  -H "Content-Type: application/json" \
  -d "{\"orderId\": \"ORD1234567890123\"}"
```

## Testing on Physical Mobile Device 📱

1. Find your computer's local IP address:
   ```bash
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.100)
   ```

2. Update `frontend/main.dart` line 101:
   ```dart
   static const String backendUrl = 'http://192.168.1.100:3000';
   ```

3. Connect your phone via USB or ensure it's on same WiFi

4. Run:
   ```bash
   cd frontend
   flutter run
   ```

## 🎯 What You Should See

### In Flutter App:
1. **Home Screen** - Two payment buttons (RM 25.50 and RM 100.00)
2. **Payment Screen** - QR code displayed with order details
3. **Status** - "WAITING" in orange
4. **Simulate Button** - Click to trigger payment
5. **Success** - Status changes to "PAID" in green after ~7 seconds

### In Browser Test Page:
1. Click amount button
2. QR code appears
3. Order information displayed
4. Click "Simulate Payment"
5. Status updates from WAITING to PAID

## Troubleshooting

### Port 3000 Already in Use
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Then restart server
```

### Flutter Pub Get Fails
```bash
flutter clean
flutter pub get
```

### Cannot Connect from Mobile Device
- Ensure firewall allows port 3000
- Verify both devices on same WiFi
- Use computer's local IP (not localhost)
- Check Windows Firewall settings

### QR Code Not Showing
- Check backend console for errors
- Verify backend is running
- Check browser console (F12)
- Try refreshing the page

## 📊 Expected Output

### Backend Console:
```
✅ Order created: ORD1729180000123 for RM25.50
🎭 Simulating payment for order ORD1729180000123...
💰 Payment received for order ORD1729180000123 - Status: PAID
```

### Flutter/Browser:
- QR Code Image (black and white squares)
- Order ID: ORD...
- Amount: RM XX.XX
- Status: WAITING → PAID

## Next Steps

- Read full [README_DUITNOW_TEST.md](README_DUITNOW_TEST.md) for detailed documentation
- Modify amounts in `frontend/main.dart`
- Integrate with your actual DuitNow account
- Add database persistence
- Implement proper authentication

## Support

If something doesn't work:
1. Check all prerequisites are installed
2. Verify backend is running (check http://localhost:3000/health)
3. Check console logs for errors
4. Try the HTML test page first (simplest)

Happy Testing! 🎉

