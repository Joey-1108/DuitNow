# DuitNow QR Payment - Architecture & Flow

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT LAYER                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │   Flutter    │         │   Browser    │                  │
│  │  Mobile App  │         │  Test Page   │                  │
│  │              │         │   (HTML)     │                  │
│  │  main.dart   │         │              │                  │
│  └──────┬───────┘         └──────┬───────┘                  │
│         │                        │                           │
│         └────────────┬───────────┘                           │
│                      │                                       │
│                      │ HTTP/REST                             │
│                      │ (JSON)                                │
└──────────────────────┼───────────────────────────────────────┘
                       │
                       │ Port 3000
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                     SERVER LAYER                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Express.js Server (duitnow-test-server.js)    │  │
│  │                                                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │  │
│  │  │  API Routes │  │   CORS      │  │  JSON Parser │  │  │
│  │  └─────────────┘  └─────────────┘  └──────────────┘  │  │
│  │                                                         │  │
│  │  Endpoints:                                             │  │
│  │  • POST /api/create-order                              │  │
│  │  • GET  /api/order/:orderId                            │  │
│  │  • POST /api/simulate-payment                          │  │
│  │  • POST /api/payment-callback                          │  │
│  │  • GET  /api/orders                                    │  │
│  │  • GET  /health                                        │  │
│  └────────────────────┬──────────────────────────────────┘  │
│                       │                                      │
│                       ↓                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │       mockDuitNowAPI.js (QR Generation Module)         │ │
│  │                                                          │ │
│  │  Functions:                                              │ │
│  │  • buildPayload()          - Create EMV string          │ │
│  │  • crc16ccitt()            - Calculate checksum         │ │
│  │  • createDuitNowQR()       - Generate QR image          │ │
│  │  • simulatePaymentCallback() - Mock payment            │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
└───────────────────────┬───────────────────────────────────────┘
                        │
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────┐         │
│  │      In-Memory Storage (Map)                   │         │
│  │                                                  │         │
│  │  Key: orderId → Value: {                        │         │
│  │    orderId: "ORD1729...",                       │         │
│  │    amount: 25.50,                                │         │
│  │    status: "WAITING",                            │         │
│  │    qrPayload: "00020101...",                     │         │
│  │    createdAt: Date                               │         │
│  │  }                                               │         │
│  └────────────────────────────────────────────────┘         │
│                                                               │
│  Optional: PostgreSQL (db.js)                                │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## 🔄 Payment Flow Sequence

```
User/Client          Flutter App            Backend Server        Mock DuitNow API
    │                     │                        │                     │
    │  1. Select Amount   │                        │                     │
    │─────────────────────>                        │                     │
    │                     │                        │                     │
    │                     │  2. POST /create-order │                     │
    │                     │  {amount: 25.50}       │                     │
    │                     │───────────────────────>│                     │
    │                     │                        │                     │
    │                     │                        │  3. Generate QR     │
    │                     │                        │  buildPayload()     │
    │                     │                        │────────────────────>│
    │                     │                        │                     │
    │                     │                        │  4. Return QR image │
    │                     │                        │<────────────────────│
    │                     │                        │                     │
    │                     │  5. Response:          │                     │
    │                     │  {orderId, qr, status} │                     │
    │                     │<───────────────────────│                     │
    │                     │                        │                     │
    │  6. Display QR      │                        │                     │
    │<─────────────────────                        │                     │
    │                     │                        │                     │
    │                     │  7. Poll Status (3s)   │                     │
    │                     │  GET /order/:orderId   │                     │
    │                     │───────────────────────>│                     │
    │                     │<───────────────────────│                     │
    │                     │  {status: "WAITING"}   │                     │
    │                     │                        │                     │
    │  8. Click "Simulate"│                        │                     │
    │─────────────────────>                        │                     │
    │                     │                        │                     │
    │                     │  9. POST /simulate     │                     │
    │                     │───────────────────────>│                     │
    │                     │                        │                     │
    │                     │                        │ 10. Trigger Callback│
    │                     │                        │  (7s delay)         │
    │                     │                        │────────────────────>│
    │                     │                        │                     │
    │                     │ 11. Continue Polling   │                     │
    │                     │───────────────────────>│                     │
    │                     │<───────────────────────│                     │
    │                     │  {status: "WAITING"}   │                     │
    │                     │                        │                     │
    │                     │                        │ 12. Callback (7s)   │
    │                     │                        │  POST /callback     │
    │                     │                        │<────────────────────│
    │                     │                        │  {orderId, "PAID"}  │
    │                     │                        │                     │
    │                     │                        │ 13. Update Status   │
    │                     │                        │  orders.set(...)    │
    │                     │                        │                     │
    │                     │ 14. Poll Again         │                     │
    │                     │───────────────────────>│                     │
    │                     │<───────────────────────│                     │
    │                     │  {status: "PAID"}      │                     │
    │                     │                        │                     │
    │ 15. Show Success ✓  │                        │                     │
    │<─────────────────────                        │                     │
    │                     │                        │                     │
    │ 16. Stop Polling    │                        │                     │
    │                     │                        │                     │
```

## 📊 Data Flow

### Request: Create Order

```
Client                           Server
  │                                │
  ├─ POST /api/create-order        │
  │  Content-Type: application/json│
  │  Body: {                        │
  │    "amount": 25.50             │
  │  }                              │
  │                                 │
  │                            ┌────▼────┐
  │                            │ Validate│
  │                            │ Amount  │
  │                            └────┬────┘
  │                                 │
  │                            ┌────▼────────┐
  │                            │ Generate ID │
  │                            │ ORD17291... │
  │                            └────┬────────┘
  │                                 │
  │                            ┌────▼─────────┐
  │                            │ Build Payload│
  │                            │ EMV QR String│
  │                            └────┬─────────┘
  │                                 │
  │                            ┌────▼──────────┐
  │                            │ Generate QR   │
  │                            │ Base64 Image  │
  │                            └────┬──────────┘
  │                                 │
  │                            ┌────▼──────────┐
  │                            │ Store Order   │
  │                            │ status:WAITING│
  │                            └────┬──────────┘
  │                                 │
  │◄─── Response: {                 │
  │      orderId: "ORD...",         │
  │      amount: 25.50,             │
  │      qr: "data:image/png;ba...",│
  │      status: "WAITING"          │
  │    }                            │
  │                                 │
```

### Response: QR Code Structure

```
QR Code Content (EMV Format):
┌─────────────────────────────────────────────┐
│ 00 02 01 01 02 12                           │  Payload Format Indicator
│ 26 58 00 16 A0000006770101...              │  Merchant Account (DuitNow)
│ 52 04 0000                                  │  Merchant Category Code
│ 53 03 458                                   │  Currency (MYR)
│ 54 06 25.50                                 │  Transaction Amount
│ 58 02 MY                                    │  Country Code
│ 59 Your Store                               │  Merchant Name
│ 60 08 KUALALUMPUR                          │  Merchant City
│ 62 10 05 ORD1729...                        │  Order ID (Additional Data)
│ 63 04 XXXX                                  │  CRC16-CCITT Checksum
└─────────────────────────────────────────────┘
```

## 🎯 Component Responsibilities

### Frontend (Flutter)

```
main.dart
├── DuitNowTestApp (MaterialApp)
│   └── HomePage (Home Screen)
│       └── DuitNowQRPage (Payment Screen)
│           ├── State Management
│           │   ├── qrBase64 (QR image data)
│           │   ├── orderId (order identifier)
│           │   ├── status (CREATING/WAITING/PAID)
│           │   └── errorMessage (error state)
│           │
│           ├── API Methods
│           │   ├── createOrder() → POST /create-order
│           │   ├── pollStatus() → GET /order/:id (every 3s)
│           │   └── simulatePayment() → POST /simulate-payment
│           │
│           └── UI Components
│               ├── QR Code Display (Image.memory)
│               ├── Order Info (ID, Amount)
│               ├── Status Badge (Color-coded)
│               ├── Simulate Button
│               └── Error View (with retry)
```

### Backend (Node.js)

```
duitnow-test-server.js
├── Express App Setup
│   ├── CORS middleware
│   ├── JSON parser
│   └── Error handlers
│
├── Routes
│   ├── POST /api/create-order
│   │   └── Calls mockDuitNowAPI.createDuitNowQR()
│   │
│   ├── GET /api/order/:orderId
│   │   └── Returns order from Map
│   │
│   ├── POST /api/simulate-payment
│   │   └── Calls mockDuitNowAPI.simulatePaymentCallback()
│   │
│   ├── POST /api/payment-callback
│   │   └── Updates order status to PAID
│   │
│   └── GET /health
│       └── Returns {status: "ok"}
│
└── Storage
    └── orders = new Map() (in-memory)
```

```
mockDuitNowAPI.js
├── crc16ccitt(data)
│   └── Calculates CRC-16 CCITT checksum
│
├── buildPayload({orderId, amount})
│   └── Constructs EMV QR string format
│
├── createDuitNowQR(orderId, amount)
│   └── Generates base64 QR code image
│
└── simulatePaymentCallback(orderId, url)
    └── Triggers callback after 7-second delay
```

## 🔐 Security Model

```
┌──────────────────────────────────────────┐
│         CURRENT (Testing)                │
├──────────────────────────────────────────┤
│  • No authentication                     │
│  • CORS: Allow all origins               │
│  • HTTP (no encryption)                  │
│  • In-memory storage (no persistence)    │
│  • No input validation                   │
│  • No rate limiting                      │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│         PRODUCTION (Required)            │
├──────────────────────────────────────────┤
│  • JWT authentication ✓                  │
│  • CORS: Specific origins only ✓         │
│  • HTTPS with SSL certificates ✓         │
│  • Database with backups ✓               │
│  • Input sanitization (XSS, SQL) ✓       │
│  • Rate limiting (express-rate-limit) ✓  │
│  • API key validation ✓                  │
│  • Webhook signature verification ✓      │
│  • Logging & monitoring (Winston) ✓      │
│  • Error handling (no stack traces) ✓    │
└──────────────────────────────────────────┘
```

## 📈 Performance Characteristics

```
Operation                Time            Notes
─────────────────────────────────────────────────────
Create Order            ~50-100ms        QR generation
Generate QR Code        ~30-50ms         QRCode library
Poll Status (HTTP)      ~10-30ms         Simple lookup
Simulate Payment        7000ms           Intentional delay
Payment Callback        ~10ms            Map update
Total Payment Flow      ~7-8s            End-to-end

Polling Frequency:      3s interval      Configurable
Concurrent Orders:      Unlimited        In-memory
Memory Usage:           ~50KB/order      Base64 QR included
```

## 🔄 State Management

```
Order Lifecycle:
┌─────────┐
│ CREATED │ ← Initial state (not stored)
└────┬────┘
     │ Store in Map
     ↓
┌─────────┐
│ WAITING │ ← Polling starts
└────┬────┘
     │ Payment received
     ↓
┌─────────┐
│  PAID   │ ← Polling stops
└─────────┘

Optional future states:
• EXPIRED (15-min timeout)
• CANCELLED (manual cancel)
• REFUNDED (refund processed)
```

## 🧪 Testing Strategy

```
Level 1: Unit Tests (Future)
├── mockDuitNowAPI.js
│   ├── CRC calculation correctness
│   ├── Payload format validation
│   └── QR generation success

Level 2: API Tests
├── test-page.html (Manual)
├── TEST_API.bat (Automated)
└── Postman Collection (Future)

Level 3: Integration Tests
├── Flutter app ↔ Backend
├── Full payment flow
└── Error scenarios

Level 4: UI Tests
├── Flutter widget tests
├── Screenshot tests
└── Accessibility tests
```

## 📦 Deployment Options

```
Option 1: Local Development
├── Windows: START_BACKEND.bat
├── macOS/Linux: npm start
└── Flutter: flutter run

Option 2: Cloud Deployment
├── Backend: Heroku, Railway, Render
├── Database: PostgreSQL (ElephantSQL)
└── Flutter: Web hosting (Netlify, Vercel)

Option 3: Containerization
├── Docker Compose
│   ├── backend service
│   ├── postgres service
│   └── nginx reverse proxy
└── Kubernetes (production scale)
```

## 🎯 Best Practices Implemented

✅ **Code Organization**
- Separation of concerns (routes, logic, UI)
- Modular file structure
- Clear naming conventions

✅ **Error Handling**
- Try-catch blocks
- User-friendly error messages
- Graceful fallbacks

✅ **User Experience**
- Loading states
- Visual feedback
- Clear instructions

✅ **Development**
- Easy-to-run scripts
- Comprehensive documentation
- Test interfaces

## 🚀 Performance Optimization Ideas

```
Current → Future
─────────────────────────────────────────
Polling (3s)              → WebSocket (real-time)
In-memory Map             → Redis cache
HTTP                      → HTTP/2
Base64 in response        → CDN URLs
No compression            → gzip/brotli
Single process            → PM2 cluster
Sync operations           → Async/await optimized
No caching                → Response caching
```

---

This architecture provides a solid foundation for testing DuitNow QR payments while remaining simple enough to understand and extend.

