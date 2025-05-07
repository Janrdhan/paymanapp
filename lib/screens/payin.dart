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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final EasebuzzFlutter _easebuzzFlutterPlugin = EasebuzzFlutter();

  String? selectedGateway;
  String _paymentResponse = 'No payment response yet';

  Future<void> initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final cardNumber = cardController.text.trim();
    final amount = amountController.text.trim();
    final gateway = selectedGateway!;

    final accessKey = await _paymentService.getAccessKey(widget.phone, amount);
    if (accessKey == null) {
      showResponseDialog("❌ Error: Unable to get access key.");
      return;
    }

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
                showResponseDialog("❌ Payment failed or status is false.");
              }
            } else {
              showResponseDialog("⚠️ Unexpected data format in 'msg': ${jsonEncode(msgList)}");
            }
          } else {
            showResponseDialog("⚠️ Unable to verify payment:\n${jsonEncode(result)}");
          }
        } else {
          showResponseDialog("❌ Could not extract transaction ID.");
        }
      } else {
        showResponseDialog("❌ Payment failed: No response.");
      }
    } on PlatformException catch (e) {
      setState(() {
        _paymentResponse = jsonEncode({"message": "Payment failed", "error": e.message});
      });
      showResponseDialog(_paymentResponse);
    } catch (e) {
      showResponseDialog("Unexpected Error: $e");
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
                  MaterialPageRoute(builder: (context) => DashboardScreen(phone: widget.phone)),
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
      backgroundColor: Colors.white, // ✅ Force background to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: cardController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Card number is required';
                  }
                  if (value.length != 16) {
                    return 'Card number must be 16 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Gateway Type', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedGateway,
                hint: const Text('Select Gateway'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['Easebuzz', 'Razorpay', 'Layra'].map((gateway) {
                  return DropdownMenuItem<String>(
                    value: gateway,
                    child: Text(gateway),
                  );
                }).toList(),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please select a gateway' : null,
                onChanged: (value) => setState(() => selectedGateway = value),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: initiatePayment,
                  child: const Text('Proceed to Pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
