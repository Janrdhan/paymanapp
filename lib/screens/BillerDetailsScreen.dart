// ignore: file_names
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:paymanapp/screens/bank_list.dart';
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class BillerDetailsScreen extends StatefulWidget {
  final Biller biller;
  final String phone;
  final String userWalletAmount;
  final String instantPaysAmount;

  const BillerDetailsScreen({
    super.key,
    required this.phone,
    required this.biller,
    required this.userWalletAmount,
    required this.instantPaysAmount,
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
  String? _errorMessage;
  String? _paymentMode;
  String? _enquiryReferenceId;
  String? _param1;
  String? _param2;

  Map<String, dynamic> billDetails = {};

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
          'registeredMobile': regMobileController.text.trim(),
          'creditCardLast4': cardDigitsController.text.trim(),
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
        billDetails = {
          "consumerName": data["consumerName"],
          "billNumber": data["billNumber"],
          "billDate": data["billDate"],
          "dueDate": data["dueDate"],
          "totalAmount": data["totalAmount"].toString(),
          "minPayable": data["minPayable"].toString()
        };

        amountController.text = billDetails["totalAmount"];

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

  Future<void> _proceed() async {
    if (amountController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Amount is required.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final enteredAmount = double.tryParse(amountController.text.trim());
    final userWalletAmount = double.tryParse(widget.userWalletAmount);
    final instantPaysAmount = double.tryParse(widget.instantPaysAmount);

    if (enteredAmount == null || enteredAmount <= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (userWalletAmount == null || userWalletAmount < enteredAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient wallet balance")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (instantPaysAmount == null || instantPaysAmount < enteredAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service not available")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/CCBill/ProcessPayment');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'billerId': widget.biller.billerId,
          'customerMobile': regMobileController.text.trim(),
          'amount': amountController.text.trim(),
          'phone': widget.phone,
          'paymentMode': _paymentMode,
          'enquiryReferenceId': _enquiryReferenceId,
          'param1': _param1,
          'param2': _param2,
          'lastFourDigits': cardDigitsController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessScreen(phone: widget.phone)),
      );
        // showDialog(
        //   context: context,
        //   builder: (ctx) => AlertDialog(
        //     title: const Text("Success"),
        //     content: Text(data['message'] ?? 'Payment processed successfully'),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Navigator.of(ctx).pop();
        //           Navigator.of(context).pushReplacement(
        //             MaterialPageRoute(
        //                 builder: (_) => DashboardScreen(phone: widget.phone)),
        //           );
        //         },
        //         child: const Text("OK"),
        //       ),
        //     ],
        //   ),
        // );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Payment failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to process payment.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InactivityWrapper(
    child : Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
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
                    // Wallet Balance Card
                    Card(
                      color: Colors.blue.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Wallet Balance",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("User Wallet:",
                                    style: TextStyle(fontSize: 14)),
                                Text("₹${widget.userWalletAmount}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

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
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField("Registered Mobile Number", regMobileController),
                    const SizedBox(height: 12),
                    _buildTextField("Last 4 digits of Credit Card Number", cardDigitsController),
                    const SizedBox(height: 12),
                    _buildTextField("Customer Mobile", custMobileController),
                    const SizedBox(height: 20),

                    if (!_showBillDetails)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _fetchBill,
                          child: const Text("Fetch Bill",
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

                    if (_showBillDetails) ...[
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Amount is required' : null,
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
                            const Text('BILL DETAILS',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            _buildDetailRow('Consumer Name', billDetails['consumerName']),
                            _buildDetailRow('Bill Number', billDetails['billNumber']),
                            _buildDetailRow('Bill Date', billDetails['billDate']),
                            _buildDetailRow('Bill Due Date', billDetails['dueDate']),
                            _buildDetailRow('Total Due Amount', billDetails['totalAmount']),
                            _buildDetailRow('Minimum Payable Amount', billDetails['minPayable']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _proceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Proceed",
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
