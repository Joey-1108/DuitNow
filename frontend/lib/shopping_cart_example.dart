import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Shopping Cart Item Model
class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});

  double get total => price * quantity;
}

// Shopping Cart Page
class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  // Sample cart items
  final List<CartItem> cartItems = [
    CartItem(name: 'Coffee', price: 5.50, quantity: 2),
    CartItem(name: 'Sandwich', price: 12.00, quantity: 1),
    CartItem(name: 'Cake', price: 8.00, quantity: 1),
  ];

  double get cartTotal {
    return cartItems.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Cart Items List
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text('${item.quantity}x'),
                    ),
                    title: Text(item.name),
                    subtitle: Text('RM ${item.price.toStringAsFixed(2)} each'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  if (item.quantity > 1) item.quantity--;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Subtotal Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                    Text(
                      'RM ${cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Tax (6%):', style: TextStyle(fontSize: 16)),
                    Text(
                      'RM ${(cartTotal * 0.06).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RM ${(cartTotal * 1.06).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pay Now Button - Auto generates QR with calculated total
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Automatically navigate to payment with calculated total
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AutoPaymentPage(
                            amount: cartTotal * 1.06, // Including tax
                            items: cartItems,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code, size: 28),
                    label: const Text(
                      'Pay Now with DuitNow QR',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Automatic Payment Page - Generates QR immediately
class AutoPaymentPage extends StatefulWidget {
  final double amount;
  final List<CartItem> items;
  
  const AutoPaymentPage({
    super.key,
    required this.amount,
    required this.items,
  });

  @override
  State<AutoPaymentPage> createState() => _AutoPaymentPageState();
}

class _AutoPaymentPageState extends State<AutoPaymentPage> {
  String? qrBase64;
  String? orderId;
  String status = "GENERATING QR...";
  bool isLoading = true;
  String? errorMessage;
  int remainingSeconds = 60;
  DateTime? expiresAt;
  
  // Change this to your backend URL
  static const String backendUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    // Automatically create order when page loads
    createOrder();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> createOrder() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        status = "GENERATING QR...";
      });

      final res = await http.post(
        Uri.parse('$backendUrl/api/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': widget.amount}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          qrBase64 = data['qr'].split(',')[1];
          orderId = data['orderId'];
          status = "WAITING";
          isLoading = false;
          expiresAt = DateTime.parse(data['expiresAt']);
        });

        startCountdown();
        pollStatus();
      } else {
        setState(() {
          errorMessage = 'Failed to create order: ${res.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e\n\nMake sure backend is running on $backendUrl';
        isLoading = false;
      });
    }
  }

  void startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return false;
      
      if (expiresAt != null) {
        final remaining = expiresAt!.difference(DateTime.now()).inSeconds;
        
        if (mounted) {
          setState(() {
            remainingSeconds = remaining > 0 ? remaining : 0;
          });
        }
        
        if (remaining <= 0 && status == "WAITING") {
          if (mounted) {
            setState(() => status = "EXPIRED");
          }
          return false;
        }
      }
      
      return status == "WAITING" && mounted;
    });
  }

  Future<void> pollStatus() async {
    while (status == "WAITING" && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final res = await http.get(
          Uri.parse('$backendUrl/api/order/$orderId'),
        ).timeout(const Duration(seconds: 5));
        
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) {
            setState(() => status = data['status']);
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    }
  }

  Future<void> simulatePayment() async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/simulate-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment simulation triggered!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simulate payment: $e')),
        );
      }
    }
  }

  Color getStatusColor() {
    switch (status) {
      case "PAID":
        return Colors.green;
      case "EXPIRED":
        return Colors.red;
      case "WAITING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case "PAID":
        return Icons.check_circle;
      case "EXPIRED":
        return Icons.cancel;
      case "WAITING":
        return Icons.qr_code_2;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DuitNow QR Payment"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: errorMessage != null
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: createOrder,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating QR Code...'),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Order Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...widget.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity}x ${item.name}'),
                                    Text('RM ${item.total.toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Image.memory(
                            base64Decode(qrBase64!),
                            width: 250,
                            height: 250,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Countdown Timer
                        if (status == "WAITING")
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: remainingSeconds > 30 
                                  ? Colors.green.shade50 
                                  : remainingSeconds > 10
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: remainingSeconds > 30 
                                    ? Colors.green 
                                    : remainingSeconds > 10
                                        ? Colors.orange
                                        : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: remainingSeconds > 30 
                                      ? Colors.green 
                                      : remainingSeconds > 10
                                          ? Colors.orange
                                          : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Time Left: ${remainingSeconds}s',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: remainingSeconds > 30 
                                        ? Colors.green.shade800 
                                        : remainingSeconds > 10
                                            ? Colors.orange.shade800
                                            : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (status == "EXPIRED")
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm_off, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Payment time expired',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Amount
                        Text(
                          'RM ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Order ID
                        Text(
                          'Order: $orderId',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Status Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getStatusColor(),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getStatusIcon(),
                                color: getStatusColor(),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Instructions
                        if (status == "WAITING") ...[
                          const Text(
                            'Scan this QR code with your banking app',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'or simulate payment for testing',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          
                          // Simulate Payment Button
                          ElevatedButton.icon(
                            onPressed: simulatePayment,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Simulate Payment (Test)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                        
                        if (status == "PAID") ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            child: const Text('Back to Home'),
                          ),
                        ],
                        
                        if (status == "EXPIRED") ...[
                          const SizedBox(height: 16),
                          const Text(
                            'The payment window has closed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please create a new order to try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

