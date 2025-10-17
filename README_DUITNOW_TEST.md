# DuitNow QR Payment Testing Guide

This project allows you to test DuitNow QR payment functionality in a Flutter mobile app with a mock backend.

## 🏗️ Project Structure

```
DuitNow/
├── backend/
│   ├── duitnow-test-server.js    # Test server for DuitNow QR
│   ├── mockDuitNowAPI.js          # QR code generation logic
│   └── db.js                      # Database configuration
├── frontend/
│   ├── main.dart                  # Flutter app entry point
│   ├── testDuitNow.dart           # Original test widget
│   └── pubspec.yaml               # Flutter dependencies
└── package.json
```

## 🚀 Quick Start

### 1. Start the Backend Server

```bash
cd backend
node duitnow-test-server.js
```

The server will start on `http://localhost:3000`

### 2. Run the Flutter App

#### Using Chrome (Web - Easiest for testing):
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

#### Using Android Emulator:
```bash
cd frontend
flutter pub get
flutter run -d <your-device-id>
```

#### Using Physical Device:
1. Update the `backendUrl` in `frontend/main.dart`:
   ```dart
   // Change from:
   static const String backendUrl = 'http://localhost:3000';
   
   // To your computer's local IP:
   static const String backendUrl = 'http://192.168.1.XXX:3000';
   ```
2. Make sure your phone and computer are on the same WiFi network
3. Run: `flutter run`

## 📱 How to Use

1. **Launch the app** - You'll see the home screen with payment options
2. **Select an amount** - Choose to pay RM 25.50 or RM 100.00
3. **QR Code Generation** - A DuitNow QR code will be generated automatically
4. **Simulate Payment** - Click the "Simulate Payment (Test)" button to test the payment flow
5. **Status Update** - Watch as the payment status updates from WAITING → PAID (takes ~7 seconds)

## 🎯 Features

- ✅ Generate DuitNow-compliant QR codes
- ✅ Real-time payment status polling
- ✅ Simulate payment without actual banking app
- ✅ Beautiful Material Design UI
- ✅ Error handling with retry functionality
- ✅ Multiple payment amount options

## 🔧 API Endpoints

### Backend Server (http://localhost:3000)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/create-order` | Create new payment order and QR code |
| GET | `/api/order/:orderId` | Get order status |
| POST | `/api/simulate-payment` | Simulate payment completion (testing) |
| GET | `/api/orders` | List all orders (debugging) |
| GET | `/health` | Health check |

### Example Request

**Create Order:**
```bash
curl -X POST http://localhost:3000/api/create-order \
  -H "Content-Type: application/json" \
  -d '{"amount": 25.50}'
```

**Simulate Payment:**
```bash
curl -X POST http://localhost:3000/api/simulate-payment \
  -H "Content-Type: application/json" \
  -d '{"orderId": "ORD1234567890123"}'
```

## 🧪 Testing Flow

1. **Create Order** → App sends amount to backend
2. **Generate QR** → Backend creates DuitNow QR code
3. **Display QR** → App shows QR code to user
4. **Poll Status** → App checks payment status every 3 seconds
5. **Simulate Payment** → Click button to simulate payment (or scan with real banking app)
6. **Callback** → Backend receives payment callback after 7 seconds
7. **Update Status** → App displays PAID status
8. **Complete** → User can close or start new transaction

## 📋 Requirements

### Backend
- Node.js (v14 or higher)
- Dependencies (already in package.json):
  - express
  - cors
  - qrcode
  - body-parser

### Frontend
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Dependencies:
  - http package

## 🛠️ Troubleshooting

### "Failed to create order" Error
- ✅ Make sure backend server is running on port 3000
- ✅ Check if backend URL is correct in Flutter app
- ✅ Verify firewall is not blocking port 3000

### "Connection refused" on Physical Device
- ✅ Use your computer's local IP instead of localhost
- ✅ Ensure phone and computer are on same WiFi network
- ✅ Check Windows Firewall allows incoming connections on port 3000

### QR Code Not Displaying
- ✅ Check browser console for errors
- ✅ Verify backend returned valid base64 image data
- ✅ Try refreshing or restarting the app

## 🎨 Customization

### Change Payment Amounts
Edit `frontend/main.dart`, line 40-60:
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DuitNowQRPage(amount: 50.00), // Change amount
      ),
    );
  },
  // ...
)
```

### Modify Polling Interval
Edit `frontend/main.dart`, line 142:
```dart
await Future.delayed(const Duration(seconds: 3)); // Change polling interval
```

### Adjust Payment Simulation Delay
Edit `backend/mockDuitNowAPI.js`, line 39:
```javascript
}, 7000); // Change delay in milliseconds
```

## 📚 DuitNow QR Payload Format

The mock implementation generates QR codes following the EMV QR Code Specification with:
- Payload Format Indicator: `00`
- Point of Initiation: `01`
- Merchant Account: DuitNow proxy ID
- Transaction Amount: User-specified
- Country Code: `MY` (Malaysia)
- CRC16-CCITT checksum

## 🔐 Security Notes

⚠️ **This is for TESTING ONLY**
- No real payment processing
- No authentication/authorization
- In-memory storage (data lost on restart)
- No SSL/TLS encryption

For production:
- Use proper database (PostgreSQL/MySQL)
- Implement authentication
- Use HTTPS
- Integrate real DuitNow API
- Add proper error handling and logging

## 📞 Support

If you encounter issues:
1. Check backend console logs
2. Check Flutter app console/debug logs
3. Verify network connectivity
4. Test endpoints with curl/Postman

## 🎉 Success!

If everything works, you should see:
1. QR code displayed on screen
2. Order ID and amount shown
3. Status showing "WAITING"
4. After simulating payment, status changes to "PAID" with green checkmark

Happy Testing! 🚀

