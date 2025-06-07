import 'dart:convert';
import 'package:easebuzz_flutter/easebuzz_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/payment_service.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';

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
  bool _isProcessing = false;

  Future<void> initiatePayment() async {
  if (_isProcessing) return;
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  if (selectedGateway == null) {
    showResponseDialog("Please select a payment gateway.");
    return;
  }

  setState(() => _isProcessing = true);

  final cardNumber = cardController.text.trim();
  final amount = amountController.text.trim();
  final gateway = selectedGateway!;

  final accessKey = await _paymentService.getAccessKey(widget.phone, amount);
  if (accessKey == null) {
    showResponseDialog("❌ Error: Unable to get access key.");
    setState(() => _isProcessing = false);
    return;
  }

  try {
    final paymentResponse = await _easebuzzFlutterPlugin.payWithEasebuzz(accessKey, "production");

    if (paymentResponse == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => PaymentFailureScreen(phone: widget.phone),
      ));
      return;
    }

    setState(() => _paymentResponse = paymentResponse.toString());

    // Extract txnId from response string (should be improved if structured response is available)
    String cleaned = _paymentResponse.replaceAll(RegExp(r'^{|}$'), '');
    final txnIdMatch = RegExp(r'txnid:\s*([\w-]+)').firstMatch(cleaned);
    final txnId = txnIdMatch?.group(1) ?? '';

    if (txnId.isNotEmpty) {
      final result = await _paymentService.verifyPayment(txnId, widget.phone, cardNumber, amount, gateway);
      if (result["status"] == "success") {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(phone: widget.phone, amount: amount, userName: "PAYMAN"),
        ));
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => PaymentFailureScreen(phone: widget.phone),
    ));
  } on PlatformException catch (e) {
    setState(() => _paymentResponse = jsonEncode({"message": "Payment failed", "error": e.message}));
    showResponseDialog(_paymentResponse);
  } catch (e) {
    showResponseDialog("Unexpected Error: $e");
  } finally {
    setState(() => _isProcessing = false);
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
                      builder: (context) => DashboardScreen(phone: widget.phone)),
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
    return InactivityWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pay In')),
        backgroundColor: Colors.white,
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
                  items: ['Easebuzz'].map((gateway) { //'Razorpay', 'Layra'
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
                    onPressed: _isProcessing ? null : initiatePayment,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Proceed to Pay'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
