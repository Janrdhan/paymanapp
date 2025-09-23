// lib/screens/biller_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/bank_list.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:paymanapp/screens/payment_success_screen_mob.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class BillerDetailsScreen extends StatefulWidget {
  final Biller biller;
  final String phone;
  final String userWalletAmount;
  final String instantPaysAmount;
  final String customerType;

  const BillerDetailsScreen({
    super.key,
    required this.phone,
    required this.biller,
    required this.userWalletAmount,
    required this.instantPaysAmount,
    required this.customerType,
  });

  @override
  State<BillerDetailsScreen> createState() => _BillerDetailsScreenState();
}

class _BillerDetailsScreenState extends State<BillerDetailsScreen> {
  final TextEditingController regMobileController = TextEditingController();
  final TextEditingController cardDigitsController = TextEditingController();
  final TextEditingController custMobileController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _showBillDetails = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  String? _paymentMode;
  String? _enquiryReferenceId;
  String? _param1;
  String? _param2;
  String? _cardholderName;
  String? _billerResponse;
  String? _adddditionalInfo;
  String? _billFetchResponse;
  String? _MinPayable;
  String? _CuurentOutStanding;
  String? _DueDate;
  String? _TotalAmount;
  String userName = "";

  Map<String, dynamic> billDetails = {};

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    regMobileController.dispose();
    cardDigitsController.dispose();
    custMobileController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // --- Fetch bill
  Future<void> _fetchBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/CCBill/FetchCreditCardBill');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'creditCardLast4': regMobileController.text.trim(),
          'registeredMobile': cardDigitsController.text.trim(),
          'customerMobile': custMobileController.text.trim(),
          'billerId': widget.biller.billerId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _paymentMode = data['paymentMode'];
        _enquiryReferenceId = data['enquiryReferenceId'];
        _param1 = data['param1'];
        _param2 = data['param2'];
        _cardholderName = data["consumerName"];
        _billerResponse = data["billerResponse"];
        _adddditionalInfo = data["adddditionalInfo"];
        _billFetchResponse = data["billFetchResponse"];
        _MinPayable = (data["minPayable"] ?? 0).toString();
        _CuurentOutStanding = (data["cuurentOutStanding"] ?? 0).toString();
        _DueDate = data["dueDate"];
        _TotalAmount = (data["totalAmount"] ?? 0).toString();

        billDetails = {
          "consumerName": data["consumerName"],
          "dueDate": data["dueDate"],
          "totalAmount": data["totalAmount"].toString(),
          "minPayable": data["minPayable"].toString(),
        };

        amountController.text = billDetails["totalAmount"];
        userName = billDetails["consumerName"];

        setState(() {
          _showBillDetails = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data["message"] ?? "Failed to fetch bill";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please try again.";
        _isLoading = false;
      });
    }
  }

  Future<String?> _createOrder(double amount) async {
    final url = Uri.parse('${ApiHandler.baseUri}/CCBill/CreateRazorpayOrder');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"amount": amount}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        return data["orderId"];
      }
    }
    return null;
  }

  // --- Step 2: Initiate payment
  Future<void> initiatePayment() async {
    if (_isProcessing) return; // avoid double click

    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter amount to proceed")),
      );
      return;
    }

    final amountDouble = double.tryParse(amountText);
    if (amountDouble == null || amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid amount")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isProcessing = true;
    });

    final orderId = await _createOrder(amountDouble);
    setState(() => _isLoading = false);

    if (orderId == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create Razorpay order")),
      );
      return;
    }

    final options = {
      'key': 'rzp_live_2EIqs9bxOALurg',
      'amount': (amountDouble * 100).toInt(), // in paise
      'name': 'PAYMAN',
      'description': 'Credit Card Bill Payment',
      'order_id': orderId,
      'prefill': {
        'contact': custMobileController.text.trim(),
        'email': 'jurrajanardhan@gmail.com'
      },
      'method': {
        "card": true,
        "netbanking": true,
        "upi": true,
        "wallet": true
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment initiation failed")),
      );
    }
  }

  // --- Handle Razorpay success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? "N/A";
    final orderId = response.orderId ?? "N/A";
    final signature = response.signature ?? "N/A";

    final verifyUrl =
        Uri.parse('${ApiHandler.baseUri}/CCBill/VerifyRazorPayPayment');

    setState(() {
      _isLoading = true;
    });

    try {
      final verifyRes = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpayPaymentId': paymentId,
          'razorpayOrderId': orderId,
          'razorpaySignature': signature,
          'phone': widget.phone,
          'amount': double.tryParse(amountController.text.trim()) ?? 0,
          'billerId': widget.biller.billerId,
          'customerMobile': custMobileController.text.trim(),
        }),
      );

      final verifyData = jsonDecode(verifyRes.body);

      if (verifyRes.statusCode == 200 && verifyData['success'] == true) {
        await _processCCBill(paymentId, paymentMode: 'Razorpay');
        return;
      } else {
        debugPrint('Payment verification failed: ${verifyData['message']}');
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(phone: widget.phone),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Razorpay payment error: ${response.message}');
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFailureScreen(phone: widget.phone),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  // --- Centralized function to call CCBill/ProcessPayment
  Future<void> _processCCBill(String? transactionId,
      {required String paymentMode}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final url = Uri.parse('${ApiHandler.baseUri}/CCBill/ProcessPayment');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'billerId': widget.biller.billerId,
          'customerMobile': custMobileController.text.trim(),
          'amount': double.tryParse(amountController.text.trim()) ?? 0,
          'phone': widget.phone,
          'paymentMode': _paymentMode,
          'enquiryReferenceId': _enquiryReferenceId,
          'param1': _param1,
          'param2': _param2,
          'lastFourDigits': cardDigitsController.text.trim(),
          'holderMobile': regMobileController.text.trim(),
          'customerName': _cardholderName,
          'device': 'Mobile',
          'billerResponse': _billerResponse,
          'adddditionalInfo': _adddditionalInfo,
          'billFetchResponse': _billFetchResponse,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              phone: widget.phone,
              amount: amountController.text.trim(),
              userName: userName.isNotEmpty ? userName : "PAYMAN",
              customerType: widget.customerType
            ),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailureScreen(phone: widget.phone),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error calling ProcessPayment: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(phone: widget.phone),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  // --- Proceed button logic
  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;

    if (amountController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Amount is required.";
      });
      return;
    }

    final enteredAmount = double.tryParse(amountController.text.trim());
    final userWalletAmount = double.tryParse(widget.userWalletAmount) ?? 0;
    final instantPaysAmount = double.tryParse(widget.instantPaysAmount) ?? 0;

    if (enteredAmount == null || enteredAmount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    if (widget.customerType == 'new') {
      await initiatePayment();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (userWalletAmount < enteredAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient wallet balance")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (instantPaysAmount < enteredAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service not available")),
      );
      setState(() => _isLoading = false);
      return;
    }

    await _processCCBill(null, paymentMode: _paymentMode ?? 'Wallet');
  }

  // --- UI
  @override
  Widget build(BuildContext context) {
    return InactivityWrapper(
      child: WillPopScope(
        onWillPop: () async {
          if (_isLoading || _isProcessing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please wait, payment is processing..."),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Credit Card'),
            leading: const BackButton(),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.asset(
                  "assets/images/Bharat Connect Primary Logo_PNG.png",
                  height: 40,
                  width: 40,
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        if (widget.customerType != "new") ...[
                          Card(
                            color: Colors.blue.shade50,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Wallet Balance",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "User Wallet:",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        "₹${widget.userWalletAmount}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            widget.biller.iconUrl.isNotEmpty
                                ? Image.network(
                                    widget.biller.iconUrl,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.credit_card, size: 40),
                                  )
                                : const Icon(Icons.credit_card, size: 40),
                            const SizedBox(width: 12),
                            Text(
                              widget.biller.billerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          "Registered Mobile Number",
                          regMobileController,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          "Last 4 digits of Credit Card Number",
                          cardDigitsController,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          "Customer Mobile",
                          custMobileController,
                        ),
                        const SizedBox(height: 20),
                        if (!_showBillDetails)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _fetchBill,
                              child: const Text(
                                "Fetch Bill",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (_showBillDetails) ...[
                          TextFormField(
                            controller: amountController,
                            decoration: const InputDecoration(
                              labelText: "Amount",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null ||
                                    value.trim().isEmpty
                                ? 'Amount is required'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Bill Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow("Consumer Name", userName),
                                _buildDetailRow("Due Date", _DueDate),
                                _buildDetailRow("Total Amount", _TotalAmount),
                                _buildDetailRow("Min Payable", _MinPayable),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _proceed,
                              child: const Text(
                                "Proceed",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(
            value ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
