import 'dart:convert';
import 'package:easebuzz_flutter/easebuzz_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
//import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/payment_service.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';
import 'package:paymanapp/screens/travel_pg_webview.dart';

class PayInScreen extends StatefulWidget {
  final String phone;
  const PayInScreen({required this.phone, super.key});

  @override
  _PayInScreenState createState() => _PayInScreenState();
}

class _PayInScreenState extends State<PayInScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController holderNameController = TextEditingController();
  final TextEditingController holderNumberController = TextEditingController();
  final TextEditingController holderEmailController = TextEditingController();
  final TextEditingController cardController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final PaymentService _paymentService = PaymentService();
  final EasebuzzFlutter _easebuzzFlutterPlugin = EasebuzzFlutter();

  String? selectedGateway;
  List<String> gatewayList = [];

  bool _isProcessing = false;
  bool _isLoadingGateways = false;

  @override
  void initState() {
    super.initState();
    fetchGateways();
  }

  // ✅ Fetch Gateways (Corrected)
  Future<void> fetchGateways() async {
    setState(() => _isLoadingGateways = true);
    final String phone = widget.phone;

    try {
      final response = await http.get(
         Uri.parse("https://paymanfintech.in/Auth/GetGateways?mobile=$phone")
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        gatewayList = data
            .where((g) => g["app"] == true)
            .map<String>((g) => g["gatewayName"].toString())
            .toList();
      } else {
        print("Gateway API Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Gateway Fetch Error: $e");
    }

    setState(() => _isLoadingGateways = false);
  }

  Future<void> initiateEduPG(
  String amount,
  String holderName,
  String holderNumber,
  String holderEmail,
  String cardNumber,
) async {
  try {
    final parsedAmount = double.tryParse(amount) ?? 0;

    final response = await http.post(
      Uri.parse("https://edu.paymanfintech.in/JioPay/CreateOrder"),
      body: {
        "amount": parsedAmount.toString(),
        "userPhone": widget.phone,
        "cName": holderName,
        "cMobile": holderNumber,
        "cCard": cardNumber,
        "cemail": holderEmail,
        "divice": "mobile"
      },
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      final redirectUrl = data["redirectUrl"];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TravelPGWebView(   // ✅ Reusing same WebView
            paymentUrl: redirectUrl,
            phone: widget.phone,
            amount: amount,
          ),
        ),
      );
    } else {
      showResponseDialog(data["message"] ?? "EDU PG failed");
    }
  } catch (e) {
    showResponseDialog("EDU PG Error: $e");
  }
}

  Future<void> initiateTravelPG(
    String amount,
    String holderName,
    String holderNumber,
    String holderEmail,
    String cardNumber,
  ) async {
    try {
      final now = DateTime.now();
      final orderId = "PAYMAN${now.millisecondsSinceEpoch}";

      final response = await http.post(
        Uri.parse("https://fastag.paymanfintech.in/FasTag/Initiate"),
        body: {
          "orderId": orderId,
          "amount": amount,
          "actionType": "1",
          "email": holderEmail,
          "phone": widget.phone,
          "custmobile": holderNumber,
          "custname": holderName,
          "custcard": cardNumber,
          "divice": "mobile"
        },
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        final url = data["url"];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TravelPGWebView(
              paymentUrl: url,
              phone: widget.phone,
              amount: amount,
            ),
          ),
        );
      } else {
        showResponseDialog(data["message"] ?? "Travel PG failed");
      }
    } catch (e) {
      showResponseDialog("Travel PG Error: $e");
    }
  }


Future<void> initiateCashfreeEduPG(
  String amount,
  String holderName,
  String holderNumber,
  String holderEmail,
  String cardNumber,
) async {
  try {
    final now = DateTime.now();
    final orderId = "PAYMAN${now.millisecondsSinceEpoch}";
    final custId = "Cust${now.millisecondsSinceEpoch}";
    final userPhone = widget.phone;

    final orderData = {
      "order_id": orderId,
      "order_amount": double.parse(amount),
      "order_currency": "INR",
      "order_note": "Order Id:$orderId",
      "order_meta": {
        "return_url":
            "https://edu.paymanfintech.in/Edu/Return?order_id=$orderId&loginmobile=$userPhone&email=$holderEmail&cardnum=$cardNumber&holderphone=$holderNumber&holdername=$holderName&device=mobile",
            "notify_url": "https://edu.paymanfintech.in/Edu/Notify"
      },
      "customer_details": {
        "customer_id": custId,
        "customer_name": holderName,
        "customer_email": holderEmail,
        "customer_phone": holderNumber
      }
    };

    final response = await http.post(
      Uri.parse("https://edu.paymanfintech.in/Edu/CreateOrder"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(orderData),
    );

    final data = jsonDecode(response.body);

    if (data["paymentSessionId"] != null) {
      final sessionId = data["paymentSessionId"];

      final checkoutUrl =
          "https://edu.paymanfintech.in/Edu/StartCheckout?sessionId=$sessionId";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TravelPGWebView(
            paymentUrl: checkoutUrl,
            phone: userPhone,
            amount: amount,
          ),
        ),
      );
    } else {
      showResponseDialog("Failed to get session ID");
    }
  } catch (e) {
    showResponseDialog("Cashfree Edu PG Error: $e");
  }
}

  Future<void> initiatePayment() async {
    if (_isProcessing) return;
    if (!_formKey.currentState!.validate()) return;

    if (selectedGateway == null) {
      showResponseDialog("Please select a payment gateway.");
      return;
    }

    setState(() => _isProcessing = true);

    final holderName = holderNameController.text.trim();
    final holderNumber = holderNumberController.text.trim();
    final holderEmail = holderEmailController.text.trim();
    final cardNumber = cardController.text.trim();
    final amount = amountController.text.trim();
    final gateway = selectedGateway!;

    if (gateway == "Travel PG") {
      await initiateTravelPG(
          amount, holderName, holderNumber, holderEmail, cardNumber);

      setState(() => _isProcessing = false);
      return;
    }

     if (gateway == "CahfreeEdu PG") {
      await initiateCashfreeEduPG(
          amount, holderName, holderNumber, holderEmail, cardNumber);

      setState(() => _isProcessing = false);
      return;
    }

    // 🔹 EDU PG Flow
if (gateway == "EDU PG") {
  await initiateEduPG(
      amount, holderName, holderNumber, holderEmail, cardNumber);

  setState(() => _isProcessing = false);
  return;
}

    final accessKey = await _paymentService.getAccessKey(
        widget.phone, holderNumber, amount, holderName, holderEmail);

    if (accessKey == null) {
      showResponseDialog("Unable to get access key.");
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
            builder: (context) =>
                PaymentFailureScreen(phone: widget.phone),
          ),
        );
        return;
      }

      String cleaned =
          paymentResponse.toString().replaceAll(RegExp(r'^{|}$'), '');
      final txnIdMatch =
          RegExp(r'txnid:\s*([\w-]+)').firstMatch(cleaned);
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
                customerType: 'Retailer',
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
          builder: (context) =>
              PaymentFailureScreen(phone: widget.phone),
        ),
      );
    } catch (e) {
      showResponseDialog("Payment Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void showResponseDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Payment Response"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [

                TextFormField(
                  controller: holderNameController,
                  decoration: const InputDecoration(
                      labelText: 'Card Holder Name',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Card holder name is required'
                          : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: holderNumberController,
                  decoration: const InputDecoration(
                      labelText: 'Card Holder Mobile Number',
                      border: OutlineInputBorder()),
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

                TextFormField(
                  controller: holderEmailController,
                  decoration: const InputDecoration(
                      labelText: 'Card Holder Email',
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters:
                      [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount required';
                    }
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter valid amount';
                    }
                    if (parsed > 99999) {
                      return 'Amount cannot exceed 99999';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _isLoadingGateways
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: selectedGateway,
                        hint: const Text('Select Gateway'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()),
                        items: gatewayList
                            .map((gateway) =>
                                DropdownMenuItem<String>(
                                  value: gateway,
                                  child: Text(gateway),
                                ))
                            .toList(),
                        validator: (value) => value == null
                            ? 'Please select gateway'
                            : null,
                        onChanged: (value) {
                          setState(() {
                            selectedGateway = value;
                          });
                        },
                      ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing ? null : initiatePayment,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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