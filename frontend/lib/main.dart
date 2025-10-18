import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'shopping_cart_example.dart';

void main() {
  runApp(const DuitNowTestApp());
}

class DuitNowTestApp extends StatelessWidget {
  const DuitNowTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuitNow QR Payment Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuitNow QR Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'DuitNow QR Payment Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Test DuitNow QR code generation and payment simulation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DuitNowQRPage(amount: 25.50),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay RM 25.50'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DuitNowQRPage(amount: 100.00),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay RM 100.00'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '🛒 Automatic QR with Cart Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingCartPage(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Shopping Cart Demo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DuitNowQRPage extends StatefulWidget {
  final double amount;
  
  const DuitNowQRPage({super.key, required this.amount});

  @override
  State<DuitNowQRPage> createState() => _DuitNowQRPageState();
}

class _DuitNowQRPageState extends State<DuitNowQRPage> {
  String? qrBase64;
  String? orderId;
  String status = "CREATING...";
  bool isLoading = true;
  String? errorMessage;
  int remainingSeconds = 60;
  DateTime? expiresAt;
  
  // Change this to your computer's IP address when testing on physical device
  // For emulator, use 10.0.2.2 (Android) or localhost (iOS)
  static const String backendUrl = 'http://192.168.1.101:3000';

  @override
  void initState() {
    super.initState();
    createOrder();
  }
  
  @override
  void dispose() {
    // Clean up when leaving the page
    super.dispose();
  }

  Future<void> createOrder() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final res = await http.post(
        Uri.parse('$backendUrl/api/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': widget.amount}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          qrBase64 = data['qr'].split(',')[1]; // remove data:image/png;base64,
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
          return false; // Stop countdown
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
        // Continue polling even if one request fails
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
        return Icons.hourglass_empty;
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
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
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
                            onPressed: () => Navigator.pop(context),
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

