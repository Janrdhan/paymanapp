import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class FetchBillScreen extends StatefulWidget {
  final String billerId;
  final String userPhone;
  final String customerPhone;
  final String serviceNumber;

  const FetchBillScreen({
    super.key,
    required this.billerId,
    required this.userPhone,
    required this.customerPhone,
    required this.serviceNumber,
  });

  @override
  State<FetchBillScreen> createState() => _FetchBillScreenState();
}

class _FetchBillScreenState extends State<FetchBillScreen> {
  bool isLoading = false;
  bool billFetched = false;

  Map<String, dynamic>? billDetails;

  @override
  void initState() {
    super.initState();
    fetchBill();
  }

  Future<void> fetchBill() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiHandler.baseUri}/BillPayments/FetchBill');

      final body = {
        "billerId": widget.billerId,
        "userPhone": widget.userPhone,
        "customerMobile": widget.customerPhone,
        "billPaymentValue": widget.serviceNumber,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("Bill Details Response: ${jsonEncode(jsonData)}");

        setState(() {
          billDetails = jsonData;
          billFetched = true;
        });
      } else {
        debugPrint("Error Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("FetchBill Error: $e");
    }

    setState(() => isLoading = false);
  }

  void processPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Process Payment API will be called here")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bill Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : billFetched
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Customer Name: ${billDetails!['customerName']}"),
                      Text("Bill Amount: ₹${billDetails!['amount']}"),
                      Text("Bill Date: ${billDetails!['billDate']}"),
                      const SizedBox(height: 20),

                      // Process Payment Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: processPayment,
                          child: const Text("Process Payment"),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    "No Bill Found",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
    );
  }
}
