import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DuitNowQRPage extends StatefulWidget {
  const DuitNowQRPage({super.key});

  @override
  State<DuitNowQRPage> createState() => _DuitNowQRPageState();
}

class _DuitNowQRPageState extends State<DuitNowQRPage> {
  String? qrBase64;
  String? orderId;
  String status = "CREATING...";

  @override
  void initState() {
    super.initState();
    createOrder();
  }

  Future<void> createOrder() async {
    final res = await http.post(
      Uri.parse('http://localhost:3000/api/create-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': 25.50}),
    );

    final data = jsonDecode(res.body);
    setState(() {
      qrBase64 = data['qr'].split(',')[1]; // remove data:image/png;base64,
      orderId = data['orderId'];
      status = "WAITING";
    });

    pollStatus();
  }

  Future<void> pollStatus() async {
    while (status == "WAITING") {
      await Future.delayed(const Duration(seconds: 3));
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/order/$orderId'),
      );
      final data = jsonDecode(res.body);
      setState(() => status = data['status']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay with DuitNow QR")),
      body: Center(
        child: qrBase64 == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.memory(base64Decode(qrBase64!)),
                  const SizedBox(height: 20),
                  Text("Order: $orderId"),
                  Text("Status: $status",
                      style: TextStyle(
                          fontSize: 18,
                          color: status == "PAID" ? Colors.green : Colors.orange)),
                ],
              ),
      ),
    );
  }
}
