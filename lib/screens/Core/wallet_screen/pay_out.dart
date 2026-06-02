import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/Core/PayinGateways/payment_failure.dart';
import 'package:paymanapp/screens/Core/PayinGateways/payment_success.dart';
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class PayOutScreen extends StatefulWidget {
  final String phone;
  const PayOutScreen({super.key, required this.phone});

  @override
  State<PayOutScreen> createState() => _PayOutScreenState();
}

class _PayOutScreenState extends State<PayOutScreen> {
  List<dynamic> _beneficiaries = [];
  List<dynamic> _filteredBeneficiaries = [];
  List<String> _bankList = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false;

  double _walletBalance = 0.0;
  double _payoutBankAmount = 0.0;
  int _payOutMaxAmount = 0;
  int _payOutMinAmount = 0;
  int _minBalanceAvl = 0;
  bool _isFetchingDetails = true;

  final String baseUrl = "${ApiHandler.baseUri}/PayOut";
  final String baseUrl1 = "${ApiHandler.baseUri}/CsbPayout";
  final TextEditingController _searchController = TextEditingController();

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _setPayoutDefaults() {
    setState(() {
      _payoutBankAmount = 50000;
      _payOutMaxAmount = 2000000;
      _payOutMinAmount = 100;
      _minBalanceAvl = 100;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _searchController.addListener(_filterBeneficiaries);
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchWalletBalance(),
      _fetchPayoutDetails(),
      _fetchBeneficiaries(),
      _fetchBankList(),
    ]);
    if (mounted) setState(() => _isFetchingDetails = false);
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetBalance?userPhone=${widget.phone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _walletBalance = _toDouble(data['balance']));
      }
    } catch (e) {
      print("Balance fetch error: $e");
    }
  }

  Future<void> _fetchPayoutDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Miscellaneous/GetPayoutConfigurationDetails?userPhone=${widget.phone}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _payoutBankAmount = _toDouble(data['payoutBankAmount']);
          _payOutMaxAmount = _toInt(data['payOutMaxAmount']) ?? 2000000;
          _payOutMinAmount = _toInt(data['payOutMinAmount']) ?? 100;
          _minBalanceAvl = _toInt(data['minBalanceAvl']) ?? 100;
        });
      } else {
        _setPayoutDefaults();
      }
    } catch (e) {
      print("Payout details error: $e");
      _setPayoutDefaults();
    }
  }

  Future<void> _fetchBeneficiaries() async {
    try {
      final url = Uri.parse("$baseUrl/GetBeneficiaries");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['beneficiaries'] != null) {
        setState(() {
          _beneficiaries = data['beneficiaries'];
          _filteredBeneficiaries = _beneficiaries;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No beneficiaries found")),
        );
      }
    } catch (e) {
      print("Error fetching beneficiaries: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBankList() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/GetBanks"));
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['banks'] != null) {
        setState(() => _bankList = List<String>.from(data['banks']));
      }
    } catch (e) {
      print("Error fetching bank list: $e");
    }
  }

  void _filterBeneficiaries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBeneficiaries = _beneficiaries
          .where((b) => b['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  void _showAddBeneficiaryDialog() {
    final formKey = GlobalKey<FormState>();
    final mobileController = TextEditingController();
    final nameController = TextEditingController();
    final accountController = TextEditingController();
    String? selectedTxn;
    String? selectedBank;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Add Beneficiary"),
            CloseButton(),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                _buildDialogTextField(mobileController, "Mobile Number", Icons.phone_android),
                const SizedBox(height: 12),
                _buildDialogTextField(nameController, "Account Holder Name", Icons.person),
                const SizedBox(height: 12),
                _buildDialogTextField(accountController, "Account Number", Icons.account_balance, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTxn,
                  items: const ['IMPS'].map((txn) => DropdownMenuItem(value: txn, child: Text(txn))).toList(),
                  onChanged: (val) => selectedTxn = val,
                  decoration: const InputDecoration(labelText: "TXN Type", border: OutlineInputBorder()),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBank,
                  items: _bankList.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                  onChanged: (val) => selectedBank = val,
                  decoration: const InputDecoration(labelText: "Select Bank", border: OutlineInputBorder()),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final response = await http.post(
                  Uri.parse("$baseUrl/AddBeneficiary"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "mobileNumber": mobileController.text.trim(),
                    "name": nameController.text.trim(),
                    "accountNumber": accountController.text.trim(),
                    "txnType": selectedTxn,
                    "bankName": selectedBank,
                    "userPhone": widget.phone
                  }),
                );

                final data = jsonDecode(response.body);
                if (data['success'] == true) {
                  Navigator.pop(context);
                  _fetchBeneficiaries();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Beneficiary added")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${data['message']}")),
                  );
                }
              }
            },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2563EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _deleteBeneficiary(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this beneficiary?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse("$baseUrl/DeleteBeneficiary"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"id": id}),
        );
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _fetchBeneficiaries();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beneficiary deleted")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: ${data['message']}")));
        }
      } catch (e) {
        print("Delete error: $e");
      }
    }
  }

  Future<String?> _showPinDialog() async {
    final pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "PIN", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN cannot be empty")));
                return;
              }
              Navigator.pop(context, pin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<bool> _validatePin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ValidatePin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone, "pin": pin}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print("PIN validation error: $e");
      return false;
    }
  }

  Future<void> _verifyBeneficiary(int index, String id) async {
    try {
      final url = Uri.parse("$baseUrl/VerifyBeneficiary");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Id": id}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _fetchBeneficiaries();
          _beneficiaries[index]['isVerified'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verified: $id")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification failed: ${data['message']}")));
      }
    } catch (e) {
      print("Verification error: $e");
    }
  }

  Future<void> _payToBeneficiary(String id, String amount, VoidCallback onComplete) async {
    try {
      final url = Uri.parse("$baseUrl1/PayToBeneficiary");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "amount": double.tryParse(amount) ?? 0.0,
          "userPhone": widget.phone,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final objRoot = data['objRoot'];
        final userName = objRoot['accoutHolderName'] ?? "N/A";
        final amountRef = objRoot['orderRefNo'].toString();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccess(
              phone: widget.phone,
              amount: amountRef,
              userName: userName,
              customerType: 'Retailer',
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailure(phone: widget.phone),
          ),
        );
      }
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentFailure(phone: widget.phone),
        ),
      );
    } finally {
      onComplete();
    }
  }

  // Helper to show a non-dismissible loading dialog
  Future<void> _showProcessingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              const Text("Processing payment, please wait..."),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingDetails) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          title: const Text("Send Money"),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isProcessingPayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment is processing, please wait…")),
          );
          return false;
        }
        return true;
      },
      child: InactivityWrapper(
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          appBar: AppBar(
            title: const Text("Send Money"),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
                onPressed: _showAddBeneficiaryDialog,
                tooltip: "Add Beneficiary",
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("₹${_walletBalance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Search beneficiary...",
                                prefixIcon: Icon(Icons.search, color: Color(0xFF2563EB)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredBeneficiaries.isEmpty
                          ? const Center(child: Text("No beneficiaries found"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredBeneficiaries.length,
                              itemBuilder: (context, index) {
                                final beneficiary = _filteredBeneficiaries[index];
                                final amountController = TextEditingController();
                                final isVerified = beneficiary['isVerified'] == true;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), shape: BoxShape.circle),
                                              child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteBeneficiary(beneficiary['id']),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(beneficiary['name'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text("Mobile: ${beneficiary['mobileNumber']}"),
                                        Text("Account: ${beneficiary['accountNumber']}"),
                                        Text("IFSC: ${beneficiary['ifscCode']}"),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Text("Status: "),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isVerified ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isVerified ? "Verified" : "Not Verified",
                                                style: TextStyle(color: isVerified ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: amountController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: "Enter amount",
                                            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isVerified ? null : () => _verifyBeneficiary(index, beneficiary['id']),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isVerified ? Colors.grey : const Color(0xFF2563EB),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                                ),
                                                child: const Text("Verify"),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: (isVerified && !_isProcessingPayment)
                                                    ? () async {
                                                        // Guard against multiple clicks
                                                        if (_isProcessingPayment) return;
                                                        setState(() => _isProcessingPayment = true);

                                                        final amountText = amountController.text.trim();
                                                        if (amountText.isEmpty) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("Enter amount")),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        final enteredAmount = double.tryParse(amountText);
                                                        final userWalletAmount = _walletBalance;
                                                        final pineLabsAmount = _payoutBankAmount;
                                                        final minAmount = _payOutMinAmount;
                                                        final maxAmount = _payOutMaxAmount;
                                                        final minBalAvl = _minBalanceAvl;

                                                        if (enteredAmount == null || enteredAmount < minAmount || enteredAmount > maxAmount) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text("Amount must be between ₹$minAmount and ₹$maxAmount"),
                                                            ),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        if (userWalletAmount < enteredAmount) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("Insufficient wallet balance")),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        if (pineLabsAmount < enteredAmount) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("Service not available")),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        final avlbal = userWalletAmount - enteredAmount;
                                                        if (avlbal < minBalAvl) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                "Insufficient wallet balance. You must maintain at least ₹$minBalAvl in your wallet.",
                                                              ),
                                                            ),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        final pin = await _showPinDialog();
                                                        if (pin == null || pin.length != 6) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("PIN must be 6 digits")),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        final isValidPin = await _validatePin(pin);
                                                        if (!isValidPin) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text("Invalid PIN")),
                                                          );
                                                          setState(() => _isProcessingPayment = false);
                                                          return;
                                                        }

                                                        final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text("Confirm Payment"),
                                                            content: RichText(
                                                              text: TextSpan(
                                                                style: Theme.of(context).textTheme.bodyMedium,
                                                                children: [
                                                                  TextSpan(text: "Send ₹$enteredAmount to "),
                                                                  TextSpan(
                                                                    text: beneficiary['name'],
                                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                                  ),
                                                                  const TextSpan(text: "?"),
                                                                ],
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, false),
                                                                child: const Text("Cancel"),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: const Color(0xFF2563EB),
                                                                ),
                                                                child: const Text("Confirm"),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirmed == true) {
                                                          // Show processing dialog (blocks all interactions)
                                                          _showProcessingDialog();
                                                          await _payToBeneficiary(
                                                            beneficiary['id'],
                                                            amountText,
                                                            () {
                                                              // This callback runs after payment API finishes (success/error)
                                                              if (mounted) {
                                                                Navigator.of(context, rootNavigator: true).pop(); // close dialog
                                                              }
                                                            },
                                                          );
                                                        } else {
                                                          setState(() => _isProcessingPayment = false);
                                                        }
                                                      }
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isVerified ? const Color(0xFF2563EB) : Colors.grey,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                                ),
                                                child: const Text("Pay"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}