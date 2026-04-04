import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/payment_success_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class BBPSPaymentScreen extends StatefulWidget {
  final dynamic biller;
  final Map<String, String> parsedBill;
  final String rawXml;
  final String additionalInfo;
  final String billFetchResponse;
  final String billerResponse;
  final String userPhone;
  final String category;
  final String device;
  final List inputs;
  final double amount;
  final String enquiryReferenceId;

  const BBPSPaymentScreen({
    super.key,
    required this.biller,
    required this.parsedBill,
    required this.rawXml,
    required this.additionalInfo,
    required this.billFetchResponse,
    required this.billerResponse,
    required this.userPhone,
    required this.category,
    required this.device,
    required this.inputs,
    required this.amount,
    required this.enquiryReferenceId,
  });

  @override
  State<BBPSPaymentScreen> createState() => _BBPSPaymentScreenState();
}

class _BBPSPaymentScreenState extends State<BBPSPaymentScreen> {
  bool isLoading = false;

  void showToast(String msg) {
    Fluttertoast.showToast(msg: msg);
  }

  Future<void> pay() async {
    setState(() => isLoading = true);
    print(widget.additionalInfo);

    try {
      final res = await http.post(
        Uri.parse('${ApiHandler.baseUri}/BillPayments/BBPSPayBill'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "billerId": widget.biller['billerId'],
          "userPhone": widget.userPhone,
          "amount": widget.amount,
          "category": widget.category,
          "device": widget.device,
          "enquiryReferenceId": widget.enquiryReferenceId,

          /// 🔥 IMPORTANT XML
          "billFetchResponse": widget.billFetchResponse,
          "billerResponse": widget.billerResponse,
          "additionalInfo": widget.additionalInfo,

          "inputs": widget.inputs,
        }),
      );

      final data = jsonDecode(res.body);

      setState(() => isLoading = false);

      if (res.statusCode != 200) {
        showToast("Server Error");
        return;
      }

      if (data["success"] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              phone: data["userPhone"] ?? "",
              amount: data["amount"] ?? "",
              userName: data["userName"] ?? "",
              customerType: "BBPS",
            ),
          ),
        );
      } else {
        showToast(data["message"] ?? "Payment Failed");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailureScreen(
              phone: data["userPhone"] ?? "",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showToast("Network Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.parsedBill['billAmount'] ?? "0";

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Amount: ₹$amount",
                style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : pay,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Pay Now"),
              ),
            )
          ],
        ),
      ),
    );
  }
}