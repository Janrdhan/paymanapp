import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class ElectricityBillScreen extends StatefulWidget {
  final String phone;
  final String customerType;
  final String billerName;

  const ElectricityBillScreen({
    super.key,
    required this.phone,
    required this.customerType,
    required this.billerName,
  });

  @override
  _ElectricityBillScreenState createState() => _ElectricityBillScreenState();
}

class _ElectricityBillScreenState extends State<ElectricityBillScreen> {
  List<dynamic> billers = [];
  String? selectedBillerId;

  Map<String, dynamic>? selectedBillerDetails;

  Map<String, dynamic>? billDetails;
  bool billFetched = false;

  final TextEditingController serviceNumberController = TextEditingController();
  final TextEditingController customerMobileController = TextEditingController();

  bool isLoading = false;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    customerMobileController.text = widget.phone;
    fetchBillers();
  }

  // 🔥 Fetch billers
  Future<void> fetchBillers() async {
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
          .replace(queryParameters: {
        'billerName': widget.billerName,
        'userPhone': widget.phone,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          billers = data['billers'];
        });
      }
    } catch (e) {
      print("Error fetching billers: $e");
    }

    setState(() => isLoading = false);
  }

  // 🔥 Fetch biller category details
  Future<void> fetchBillerDetails(String billerId) async {
    try {
      final uri =
          Uri.parse('${ApiHandler.baseUri}/BillPayments/CheckBillerCategory')
              .replace(queryParameters: {
        'billerId': billerId,
        'userPhone': widget.phone,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          selectedBillerDetails = data;
        });

        print("Biller details loaded: $data");
      }
    } catch (e) {
      print("Error loading biller details: $e");
    }
  }

  // 🔥 Enable button
  void checkButtonState() {
    setState(() {
      isButtonEnabled = selectedBillerId != null &&
          serviceNumberController.text.isNotEmpty &&
          customerMobileController.text.isNotEmpty;
    });
  }

  // 🔥 Fetch Bill (POST)
  Future<void> fetchBill() async {
    if (!isButtonEnabled) return;

    setState(() => isLoading = true);

    final url = Uri.parse("${ApiHandler.baseUri}/BillPayments/FetchBill");

    final body = {
      "billerId": selectedBillerId,
      "billPaymentValue": serviceNumberController.text,
      "customerMobile": customerMobileController.text,
      "userPhone": widget.phone
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        print("Bill Details Response: ${jsonEncode(jsonData)}"); // 🔥 PRINT

        setState(() {
          billDetails = jsonData;
          billFetched = true;
        });
      } else {
        print("Fetch Bill Failed");
      }
    } catch (e) {
      print("Error Fetching Bill: $e");
    }

    setState(() => isLoading = false);
  }

  // 🔥 Process Payment
  void processPayment() {
    print("Processing payment...");
    print("Bill Details: $billDetails");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Electricity Bill")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================
                  // 🔽 BILLER DROPDOWN
                  // ===========================
                  Text(
                    "Select Electricity Biller",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  DropdownButtonFormField(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Biller",
                    ),
                    items: billers.map<DropdownMenuItem<String>>((biller) {
                      return DropdownMenuItem(
                        value: biller['billerId'],
                        child: Text(biller['billerName']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBillerId = value;
                        selectedBillerDetails = null;
                        billFetched = false;
                      });

                      fetchBillerDetails(value!);
                      checkButtonState();
                    },
                  ),

                  SizedBox(height: 20),

                  // ===========================
                  // 🔢 SERVICE NUMBER
                  // ===========================
                  TextField(
                    controller: serviceNumberController,
                    onChanged: (_) => checkButtonState(),
                    decoration: InputDecoration(
                      labelText: "Service Number / Consumer Number",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 20),

                  // ===========================
                  // 📱 CUSTOMER MOBILE
                  // ===========================
                  TextField(
                    controller: customerMobileController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Customer Mobile",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  SizedBox(height: 30),

                  // ===========================
                  // 🔘 FETCH BILL BUTTON
                  // ===========================
                  if (!billFetched)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled ? fetchBill : null,
                        child: Text("Fetch Bill"),
                      ),
                    ),

                  // ===========================
                  // 📘 SHOW BILL DETAILS
                  // ===========================
                  if (billFetched && billDetails != null) ...[
                    Divider(),
                    Text("Bill Details",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),

                    Text("Customer Name: ${billDetails!['customerName'] ?? ''}"),
                    Text("Bill Amount: ₹${billDetails!['billAmount'] ?? ''}"),
                    Text("Bill Date: ${billDetails!['billDate'] ?? ''}"),
                    Text("Due Date: ${billDetails!['dueDate'] ?? ''}"),

                    SizedBox(height: 20),

                    // ===========================
                    // 🔘 PAY NOW BUTTON
                    // ===========================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: processPayment,
                        child: Text("Process Payment"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
