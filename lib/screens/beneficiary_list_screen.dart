import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/inactivity_wrapper.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';
import 'package:paymanapp/screens/user_profile_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class BeneficiaryListScreen extends StatefulWidget {
  final String phone;
  final String userWalletAmount;
  final String pineLabsAmount;
  final int payOutMaxAmount;
  final int payOutMinAmount;
  final int minBalanceAvl;

  const BeneficiaryListScreen({
    super.key,
    required this.phone,
    required this.userWalletAmount,
    required this.pineLabsAmount,
    required this.payOutMaxAmount,
    required this.payOutMinAmount,
    required this.minBalanceAvl
  });

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  List<dynamic> _beneficiaries = [];
  List<dynamic> _filteredBeneficiaries = [];
  List<String> _bankList = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false; // ✅ Track payment state

  final String baseUrl = "${ApiHandler.baseUri}/PayOut";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBeneficiaries();
    _fetchBankList();
    _searchController.addListener(_filterBeneficiaries);
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
        setState(() {
          _bankList = List<String>.from(data['banks']);
        });
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
          children: [
            const Text("Add Beneficiary"),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: "Mobile Number"),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Account Holder Name"),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: accountController,
                  decoration: const InputDecoration(labelText: "Account No"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedTxn,
                  items: ['IMPS']
                      .map((txn) => DropdownMenuItem(value: txn, child: Text(txn)))
                      .toList(),
                  onChanged: (val) => selectedTxn = val,
                  decoration: const InputDecoration(labelText: "TXN Type"),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedBank,
                  items: _bankList
                      .map((bank) => DropdownMenuItem(value: bank, child: Text(bank)))
                      .toList(),
                  onChanged: (val) => selectedBank = val,
                  decoration: const InputDecoration(labelText: "Select Bank"),
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
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Future<void> _deleteBeneficiary(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this beneficiary?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Beneficiary deleted")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete failed: ${data['message']}")),
          );
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "PIN", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN cannot be empty")),
                );
                return;
              }
              Navigator.pop(context, pin);
            },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verified: $id")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${data['message']}")),
        );
      }
    } catch (e) {
      print("Verification error: $e");
    }
  }

   Future<void> _payToBeneficiary(String id, String amount) async {
    try {
      setState(() {
        _isLoading = true;
        _isProcessingPayment = true; // ✅ block back
      });

      final url = Uri.parse("$baseUrl/PayToBeneficiary");
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
      print(data);

      if (data['success'] == true) {
        final objRoot = data['objRoot'];
        final userName = objRoot['accoutHolderName'] ?? "N/A";
        final amount = objRoot['orderRefNo'].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              phone: widget.phone,
              amount: amount,
              userName: userName,
              customerType: 'Retailer'
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFailureScreen(phone: widget.phone),
          ),
        );
      }
    } catch (e) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(phone: widget.phone),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessingPayment = false; // ✅ allow back again
        });
      }
    }
  }
  void showResponseDialog(String message, {bool success = false}) async {
  if (success) {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success-68578.mp3'));
  }

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
                MaterialPageRoute(builder: (context) => UserProfileScreen(phone: widget.phone)),
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
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessingPayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment is processing, please wait…")),
          );
          return false; // 🚫 block back
        }
        return true; // ✅ allow normal back
      },
    child: InactivityWrapper(
     child:Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text("Beneficiary List"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddBeneficiaryDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Wallet Balance: ₹${widget.userWalletAmount}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredBeneficiaries.length,
                    itemBuilder: (context, index) {
                      final beneficiary = _filteredBeneficiaries[index];
                      final controller = TextEditingController();
                      final isVerified = beneficiary['isVerified'] == true;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Mobile: ${beneficiary['mobileNumber']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteBeneficiary(beneficiary['id']),
                                  ),
                                ],
                              ),
                               RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: [
        const TextSpan(text: "Name: "),
        TextSpan(
          text: "${beneficiary['name']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  ),
                              Text("Account Number: ${beneficiary['accountNumber']}"),
                              Text("IFSC Code: ${beneficiary['ifscCode']}"),
                              Text(
                                "Status: ${isVerified ? 'Verified' : 'Not Verified'}",
                                style: TextStyle(
                                  color: isVerified ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: "Enter amount",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: isVerified
                                        ? null
                                        : () => _verifyBeneficiary(index, beneficiary['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isVerified ? Colors.grey : Colors.green,
                                    ),
                                    child: const Text("Verify"),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: isVerified
                                        ? () async {
                                            final amountText = controller.text.trim();
                                            if (amountText.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Please enter an amount")),
                                              );
                                              return;
                                            }

                                            final enteredAmount = double.tryParse(controller.text.trim());
                                            final userWalletAmount = double.tryParse(widget.userWalletAmount);
                                            final pineLabsAmount = double.tryParse(widget.pineLabsAmount);

                                            final minAmount = widget.payOutMinAmount;
                                            final maxAmount = widget.payOutMaxAmount;
                                            final minBalAvl = widget.minBalanceAvl;

                                            

                                            if (enteredAmount == null || enteredAmount < minAmount || enteredAmount > maxAmount) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                         SnackBar(
                                                          content: Text("Enter an amount between ₹$minAmount and ₹$maxAmount"),
                                                          ),
                                                     );
                                               return;
                                            }

                                            if (userWalletAmount == null || userWalletAmount < enteredAmount) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Insufficient wallet balance")),
                                              );
                                              return;
                                            }

                                            if (pineLabsAmount == null || pineLabsAmount < enteredAmount) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Service not available")),
                                              );
                                              return;
                                            }

                                            final avlbal = userWalletAmount - enteredAmount;

// Check if available balance falls below minimum required balance
if (avlbal < minBalAvl) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Insufficient wallet balance. You must maintain at least ₹$minBalAvl in your wallet.")),
  );
  return;
}



                                            final pin = await _showPinDialog();
                                            if (pin == null || pin.length != 6) {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("PIN must be 6 digits.")),
                                                );
                                               return;
                                              }

                                            final isValidPin = await _validatePin(pin);
                                            if (!isValidPin) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Invalid PIN")),
                                              );
                                              return;
                                            }

                                            if (isValidPin) {
  // Show confirmation dialog with account holder name
  bool confirmed = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Payment'),
      content: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Do you want to proceed with the payment for '),
            TextSpan(
              text: '${beneficiary['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    setState(() => _isLoading = true); 
    // Proceed with payment
    await _payToBeneficiary(beneficiary['id'], amountText);
  }
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Invalid PIN")),
  );
}
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isVerified ? Colors.blue : Colors.grey,
                                    ),
                                    child: const Text("Pay"),
                                  ),
                                ],
                              )
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
