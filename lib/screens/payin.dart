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

  // Controllers for all fields
  final TextEditingController holderNameController = TextEditingController();
  final TextEditingController holderNumberController = TextEditingController();
  final TextEditingController holderEmailController = TextEditingController();
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

    // Collect all field values
    final holderName = holderNameController.text.trim();
    final holderNumber = holderNumberController.text.trim();
    final holderEmail = holderEmailController.text.trim();
    final cardNumber = cardController.text.trim();
    final amount = amountController.text.trim();
    final gateway = selectedGateway!;

    // Get Access Key from API
    final accessKey = await _paymentService.getAccessKey(widget.phone,holderNumber, amount, holderName, holderEmail);
    if (accessKey == null) {
      showResponseDialog("❌ Error: Unable to get access key.");
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final paymentResponse =
          await _easebuzzFlutterPlugin.payWithEasebuzz(accessKey, "production");

      if (paymentResponse == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailureScreen(phone: widget.phone),
          ),
        );
        return;
      }

      setState(() => _paymentResponse = paymentResponse.toString());

      // Extract txnId from response string
      String cleaned = _paymentResponse.replaceAll(RegExp(r'^{|}$'), '');
      final txnIdMatch = RegExp(r'txnid:\s*([\w-]+)').firstMatch(cleaned);
      final txnId = txnIdMatch?.group(1) ?? '';

      if (txnId.isNotEmpty) {
        final result = await _paymentService.verifyPayment(
          txnId,
          widget.phone,
          cardNumber,
          amount,
          gateway,
          holderName,
          holderNumber,
          holderEmail,
        );

        if (result["status"] == "success") {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                phone: widget.phone,
                amount: amount,
                userName: "PAYMAN",
              ),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(phone: widget.phone),
        ),
      );
    } on PlatformException catch (e) {
      setState(() => _paymentResponse =
          jsonEncode({"message": "Payment failed", "error": e.message}));
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
                    builder: (context) =>
                        DashboardScreen(phone: widget.phone),
                  ),
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
                // Card Holder Name
                TextFormField(
                  controller: holderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Card holder name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Card Holder Number
                TextFormField(
                  controller: holderNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Card holder number is required';
                    }
                    if (value.length != 10) {
                      return 'Card holder number must be 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Card Holder Email
                TextFormField(
                  controller: holderEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Card Number
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

                // Amount
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
                    final parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue <= 0) {
                         return 'Enter a valid amount';
                    }
                    if (parsedValue > 99999) {
                        return 'Amount cannot be more than 99999';
                      }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gateway Dropdown
                const Text('Gateway Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: selectedGateway,
                  hint: const Text('Select Gateway'),
                  isExpanded: true,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: ['Easebuzz'].map((gateway) {
                    return DropdownMenuItem<String>(
                      value: gateway,
                      child: Text(gateway),
                    );
                  }).toList(),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a gateway'
                      : null,
                  onChanged: (value) =>
                      setState(() => selectedGateway = value),
                ),
                const SizedBox(height: 24),

                // Submit Button
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
