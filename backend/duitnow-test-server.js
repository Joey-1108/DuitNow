import express from 'express';
import cors from 'cors';
import { createDuitNowQR, simulatePaymentCallback } from './mockDuitNowAPI.js';

const app = express();
const PORT = 3000;

// In-memory storage for testing (replace with database in production)
const orders = new Map();

app.use(cors());
app.use(express.json());

// Create a new order and generate QR code
app.post('/api/create-order', async (req, res) => {
  try {
    const { amount } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const orderId = `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`;
    const { payload, qr } = await createDuitNowQR(orderId, amount);
    
    const expiresAt = new Date(Date.now() + 60000); // 60 seconds from now
    
    // Store order in memory
    orders.set(orderId, {
      orderId,
      amount,
      status: 'WAITING',
      qrPayload: payload,
      createdAt: new Date(),
      expiresAt: expiresAt,
    });

    // Auto-expire after 1 minute
    setTimeout(() => {
      const order = orders.get(orderId);
      if (order && order.status === 'WAITING') {
        order.status = 'EXPIRED';
        console.log(`⏰ Order ${orderId} expired after 1 minute`);
      }
    }, 60000);

    console.log(`✅ Order created: ${orderId} for RM${amount} (expires in 60s)`);

    res.json({
      orderId,
      amount,
      qr,
      status: 'WAITING',
      expiresAt: expiresAt.toISOString(),
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// Get order status
app.get('/api/order/:orderId', (req, res) => {
  const { orderId } = req.params;
  const order = orders.get(orderId);

  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }

  res.json({
    orderId: order.orderId,
    amount: order.amount,
    status: order.status,
    createdAt: order.createdAt,
  });
});

// Payment callback (normally called by DuitNow)
app.post('/api/payment-callback', (req, res) => {
  const { orderId, status } = req.body;
  const order = orders.get(orderId);

  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }

  order.status = status;
  order.paidAt = new Date();
  
  console.log(`💰 Payment received for order ${orderId} - Status: ${status}`);

  res.json({ success: true, orderId, status });
});

// Simulate payment (for testing purposes)
app.post('/api/simulate-payment', async (req, res) => {
  const { orderId } = req.body;
  const order = orders.get(orderId);

  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }

  if (order.status !== 'WAITING') {
    return res.status(400).json({ error: 'Order already processed' });
  }

  console.log(`🎭 Simulating payment for order ${orderId}...`);
  
  // Simulate DuitNow callback after a delay
  await simulatePaymentCallback(orderId, `http://localhost:${PORT}`);

  res.json({ 
    success: true, 
    message: 'Payment simulation triggered. Status will update in ~7 seconds.',
    orderId 
  });
});

// List all orders (for debugging)
app.get('/api/orders', (req, res) => {
  const orderList = Array.from(orders.values());
  res.json(orderList);
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

app.listen(PORT, () => {
  console.log(`\n🚀 DuitNow Test Server running on http://localhost:${PORT}`);
  console.log(`\n📱 Available endpoints:`);
  console.log(`   POST   /api/create-order        - Create new payment order`);
  console.log(`   GET    /api/order/:orderId      - Get order status`);
  console.log(`   POST   /api/simulate-payment    - Simulate payment (testing)`);
  console.log(`   GET    /api/orders              - List all orders`);
  console.log(`   GET    /health                  - Health check`);
  console.log(`\n💡 Ready to test DuitNow QR payments!\n`);
});

