// ignore: file_names
import 'dart:async';
import 'dart:convert';
import 'package:easebuzz_flutter/easebuzz_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/Core/PayinGateways/pg_webview.dart';
import 'package:paymanapp/screens/Core/PayinGateways/payment_failure.dart';   // renamed
import 'package:paymanapp/screens/Core/PayinGateways/payment_success.dart';   // renamed
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/payment_service.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class PayInScreen extends StatefulWidget {
  final String phone;
  const PayInScreen({required this.phone, super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  List<dynamic> gatewayList = [];
  String? selectedGateway;

  List<dynamic> _recentPayments = [];
  bool _isLoadingRecent = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isProcessing = false;
  bool _isLoadingGateways = false;

  @override
  void initState() {
    super.initState();
    fetchGateways();
    _fetchRecentPayments();
    _searchController.addListener(_onSearchChanged);
    holderNameController.addListener(_onFormChanged);
    holderNumberController.addListener(_onFormChanged);
    holderEmailController.addListener(_onFormChanged);
    cardController.addListener(_onFormChanged);
    amountController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    holderNameController.removeListener(_onFormChanged);
    holderNumberController.removeListener(_onFormChanged);
    holderEmailController.removeListener(_onFormChanged);
    cardController.removeListener(_onFormChanged);
    amountController.removeListener(_onFormChanged);
    holderNameController.dispose();
    holderNumberController.dispose();
    holderEmailController.dispose();
    cardController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPayments(_searchController.text);
    });
  }

  bool _isFormValid() {
    if (selectedGateway == null) return false;
    if (holderNameController.text.trim().isEmpty) return false;
    final phone = holderNumberController.text.trim();
    if (phone.isEmpty || phone.length != 10) return false;
    final email = holderEmailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return false;
    final card = cardController.text.trim();
    if (card.isEmpty || card.length != 16) return false;
    final amount = amountController.text.trim();
    if (amount.isEmpty) return false;
    final parsedAmount = int.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0 || parsedAmount > 99999) return false;
    return true;
  }

  Future<void> _fetchRecentPayments() async {
    setState(() => _isLoadingRecent = true);
    try {
      final url = Uri.parse('${ApiHandler.baseUri}/Auth/GetRecentPayments?mobile=${widget.phone}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _recentPayments = data);
      }
    } catch (e) {
      print("Recent payments error: $e");
    } finally {
      setState(() => _isLoadingRecent = false);
    }
  }

  Future<void> _searchPayments(String query) async {
    if (query.isEmpty) {
      await _fetchRecentPayments();
      return;
    }
    setState(() => _isLoadingRecent = true);
    try {
      final url = Uri.parse('${ApiHandler.baseUri}/Auth/SearchPayments?mobile=${widget.phone}&name=${Uri.encodeComponent(query)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _recentPayments = data);
      }
    } catch (e) {
      print("Search error: $e");
    } finally {
      setState(() => _isLoadingRecent = false);
    }
  }

  void _prefillForm(Map<String, dynamic> payment) {
    holderNameController.text = payment['creditCardHolderName'] ?? '';
    holderNumberController.text = payment['cardholderMobileNo'] ?? '';
    holderEmailController.text = payment['email'] ?? '';
    cardController.text = payment['creditCardHolderNum'] ?? '';
    amountController.text = (payment['amount'] ?? 0).toString();
    setState(() {});
  }

  Future<void> fetchGateways() async {
    setState(() => _isLoadingGateways = true);
    final String phone = widget.phone;

    try {
      final response = await http.get(
        Uri.parse("https://paymanfintech.in/Auth/GetGateways?mobile=$phone"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered = data.where((g) =>
            g["app"] == true &&
            g["isActive"] == true &&
            g["storeName"] != null &&
            g["gatewayName"] != null
        ).toList();

        final Map<String, dynamic> uniqueMap = {};
        for (var g in filtered) {
          uniqueMap[g["storeName"].toString()] = g;
        }

        gatewayList = uniqueMap.values.toList();

        if (!gatewayList.any((g) => g["storeName"] == selectedGateway)) {
          selectedGateway = null;
        }
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
        print("Redirecting to: $redirectUrl");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PGWebView(
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
            builder: (_) => PGWebView(
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
          "return_url": "https://edu.paymanfintech.in/Edu/Return?order_id=$orderId&loginmobile=$userPhone&email=$holderEmail&cardnum=$cardNumber&holderphone=$holderNumber&holdername=$holderName&device=mobile",
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderData),
      );

      final data = jsonDecode(response.body);

      if (data["paymentSessionId"] != null) {
        final sessionId = data["paymentSessionId"];
        final checkoutUrl = "https://edu.paymanfintech.in/Edu/StartCheckout?sessionId=$sessionId";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PGWebView(
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
    if (!_isFormValid()) return;

    setState(() => _isProcessing = true);

    final holderName = holderNameController.text.trim();
    final holderNumber = holderNumberController.text.trim();
    final holderEmail = holderEmailController.text.trim();
    final cardNumber = cardController.text.trim();
    final amount = amountController.text.trim();
    final gateway = selectedGateway!;

    if (gateway == "Vegaah") {
      await initiateTravelPG(amount, holderName, holderNumber, holderEmail, cardNumber);
      setState(() => _isProcessing = false);
      return;
    }

    if (gateway == "CashfreeEdu") {
      await initiateCashfreeEduPG(amount, holderName, holderNumber, holderEmail, cardNumber);
      setState(() => _isProcessing = false);
      return;
    }

    if (gateway == "JioPay") {
      await initiateEduPG(amount, holderName, holderNumber, holderEmail, cardNumber);
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
      final paymentResponse = await _easebuzzFlutterPlugin.payWithEasebuzz(accessKey, "production");

      if (paymentResponse == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailure(phone: widget.phone), // ✅ corrected
          ),
        );
        return;
      }

      String cleaned = paymentResponse.toString().replaceAll(RegExp(r'^{|}$'), '');
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
              builder: (context) => PaymentSuccess(
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
          builder: (context) => PaymentFailure(phone: widget.phone), // ✅ corrected
        ),
      );
    } catch (e) {
      showResponseDialog("Payment Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
    final bool isButtonEnabled = _isFormValid() && !_isProcessing;

    return InactivityWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: const Text('Pay In'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Add Money to Wallet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Secure payment via multiple gateways",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: holderNameController,
                  label: 'Card Holder Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: holderNumberController,
                  label: 'Card Holder Mobile Number',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: holderEmailController,
                  label: 'Card Holder Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: cardController,
                  label: 'Card Number',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: amountController,
                  label: 'Amount',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 24),

                _buildGatewayDropdown(),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled ? initiatePayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Proceed to Pay',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Recent Payments",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 0, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildSearchBar(),
                      ),
                      _buildRecentPaymentsList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (label.contains('Mobile') && value.length != 10) return '10 digits';
          if (label.contains('Email') && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email';
          if (label.contains('Card Number') && value.length != 16) return '16 digits';
          if (label.contains('Amount')) {
            final parsed = int.tryParse(value);
            if (parsed == null || parsed <= 0) return 'Valid amount';
            if (parsed > 99999) return 'Max ₹99,999';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildGatewayDropdown() {
    if (_isLoadingGateways) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedGateway,
        hint: const Text('Select Gateway'),
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.payment, color: Color(0xFF2563EB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        items: gatewayList.map<DropdownMenuItem<String>>((g) {
          return DropdownMenuItem<String>(
            value: g["storeName"].toString(),
            child: Text(g["gatewayName"].toString()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedGateway = value;
          });
        },
        validator: (value) => value == null ? 'Please select gateway' : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by card number, name or mobile",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRecentPaymentsList() {
    if (_isLoadingRecent) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recentPayments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text("No recent payments found")),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentPayments.length,
      itemBuilder: (context, index) {
        final payment = _recentPayments[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Color(0xFF2563EB)),
            ),
            title: Text(
              payment['creditCardHolderName'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Amount: ₹${payment['amount'] ?? 0}"),
                Text("Card: ${payment['creditCardHolderNum'] ?? ''}"),
                if (payment['email'] != null && payment['email'].isNotEmpty)
                  Text("Email: ${payment['email']}"),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _prefillForm(payment),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Repay"),
            ),
          ),
        );
      },
    );
  }
}