import 'dart:convert';
import 'package:easebuzz_flutter/easebuzz_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/payment_service.dart';

class PayInScreen extends StatefulWidget {
  final String phone;
  const PayInScreen({required this.phone, super.key});

  @override
  _PayInScreenState createState() => _PayInScreenState();
}

class _PayInScreenState extends State<PayInScreen> {
  final TextEditingController cardController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final EasebuzzFlutter _easebuzzFlutterPlugin = EasebuzzFlutter();

  String selectedGateway = '';
  String _paymentResponse = 'No payment response yet';

  Future<void> initiatePayment() async {
    final cardNumber = cardController.text.trim();
    final amount = mobileController.text.trim();
    final gateway = selectedGateway;

    if (cardNumber.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Card Number and Amount")),
      );
      return;
    }

    if (cardNumber.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 16-digit card number.")),
      );
      return;
    }

    if (gateway.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a gateway.")),
      );
      return;
    }

    final accessKey = await _paymentService.getAccessKey(widget.phone, amount);
    if (accessKey == null) {
      showResponseDialog("❌ Error: Unable to get access key.");
      return;
    }

    print("🛠 Access Key: $accessKey");

    try {
      final paymentResponse =
          await _easebuzzFlutterPlugin.payWithEasebuzz(accessKey, "production");

      setState(() {
        _paymentResponse = paymentResponse.toString();
      });

      if (paymentResponse != null) {
        final RegExp regExp = RegExp(r'(SRREDU\d+)');
        final match = regExp.firstMatch(_paymentResponse);

        if (match != null) {
          final txnId = match.group(0)!;
          print("✅ Extracted txnId: $txnId");

          final result = await _paymentService.verifyPayment(
              txnId, widget.phone, cardNumber, amount, gateway);

          if (result.containsKey("data")) {
            final paymentData = result["data"];
            final msgList = paymentData["msg"];

            if (msgList is List && msgList.isNotEmpty) {
              final firstMsg = msgList[0];
              final status = paymentData["status"] ?? "Unknown";
              final txnId = firstMsg["txnId"] ?? "N/A";
              final amount = firstMsg["amount"] ?? "N/A";

              final now = DateTime.now();
              String formattedDate =
                  "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

              if (status == true) {
                showResponseDialog(
                  "✅ Payment Details:\nTxn ID: $txnId\nAmount: ₹$amount\nStatus: Success\nDate: $formattedDate",
                  success: true,
                );
              } else {
                showResponseDialog(
                  "❌ Payment failed or status is false.",
                  success: false,
                );
              }
            } else {
              showResponseDialog(
                "⚠️ Unexpected data format in 'msg': ${jsonEncode(msgList)}",
                success: false,
              );
            }
          } else {
            showResponseDialog(
              "⚠️ Unable to verify payment. Raw response:\n${jsonEncode(result)}",
              success: false,
            );
          }
        } else {
          showResponseDialog(
            "❌ Could not extract transaction ID.",
            success: false,
          );
        }
      } else {
        showResponseDialog("❌ Payment failed: No response.", success: false);
      }
    } on PlatformException catch (e) {
      setState(() {
        _paymentResponse =
            jsonEncode({"message": "Payment failed", "error": e.message});
      });
      showResponseDialog(_paymentResponse);
    } catch (e) {
      showResponseDialog("Unexpected Error: $e", success: false);
    }
  }

  void showResponseDialog(String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payment Response"),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          DashboardScreen(phone: widget.phone)),
                );
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: cardController,
              decoration: const InputDecoration(labelText: 'Card Number'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            const Text('Gateway Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedGateway.isEmpty ? null : selectedGateway,
              hint: const Text('Select Gateway'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  enabled: false,
                  child: Text('Select Gateway'),
                ),
                ...['Easebuzz', 'Razorpay', 'Layra'].map(
                  (gateway) => DropdownMenuItem<String>(
                    value: gateway,
                    child: Text(gateway),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGateway = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: initiatePayment,
                child: const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
