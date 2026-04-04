import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/screens/payment_success_screen_mob.dart';

class CreditCardBillDetailsScreen extends StatefulWidget {
  final String billerId;
  final String billerName;
  final String billerLogoUrl;
  final String cardNumber;
  final String userPhone;
  final Map<String, dynamic> billData;

  const CreditCardBillDetailsScreen({
    super.key,
    required this.billerId,
    required this.billerName,
    required this.billerLogoUrl,
    required this.cardNumber,
    required this.userPhone,
    required this.billData,
  });

  @override
  State<CreditCardBillDetailsScreen> createState() =>
      _CreditCardBillDetailsScreenState();
}

class _CreditCardBillDetailsScreenState
    extends State<CreditCardBillDetailsScreen> {
  bool showMoreDetails = false;
  TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  /// 🔥 DATA EXTRACTION

  String get cardNumber {
    try {
      return widget.billData["inputParams"][0]["paramValue"] ?? "";
    } catch (_) {
      return widget.cardNumber;
    }
  }

  String get customerName {
    try {
      return widget.billData["billerResponse"]["customerName"] ?? "";
    } catch (_) {
      return "";
    }
  }

  String get billAmount {
    try {
      return widget.billData["billerResponse"]["billAmount"] ?? "0";
    } catch (_) {
      return "0";
    }
  }

  String get dueDate {
    try {
      return widget.billData["billerResponse"]["dueDate"] ?? "";
    } catch (_) {
      return "";
    }
  }

  String get minAmount {
    try {
      return widget.billData["billerResponse"]["minAmount"] ?? "";
    } catch (_) {
      return "";
    }
  }

  /// XML Fields
  String get xml_additionalInfo =>
      widget.billData["adddditionalInfo"] ?? "";

  String get xml_billerResponse =>
      widget.billData["billerResponse1"] ?? "";

  String get xml_billFetchResponse =>
      widget.billData["billFetchResponse"] ?? "";

  @override
  void initState() {
    super.initState();
    amountController.text = billAmount;
  }

  /// 💳 PROCESS PAYMENT
  Future<void> processPayment() async {
    setState(() => isLoading = true);

    final url =
        Uri.parse("${ApiHandler.baseUri}/BillPayments/ProcessBill");

    final body = {
      "billerId": widget.billerId,
      "param1": cardNumber,
      "phone": widget.userPhone,
      "amount": double.tryParse(amountController.text.trim()) ?? 0.0,
      "enquiryReferenceId":
          widget.billData["enquiryReferenceId"] ?? "",
      "billerResponse": xml_billerResponse,
      "adddditionalInfo": xml_additionalInfo,
      "billFetchResponse": xml_billFetchResponse,
      "holderMobile": widget.userPhone,
      "device": "Mobile",
      "customerName": customerName,
      "lastFourDigits":
          cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber,
      "customerMobile": widget.userPhone
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                phone: data["userPhone"],
                amount: data["amount"],
                userName: data["userName"],
                customerType: 'creditcard',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PaymentFailureScreen(phone: data["userPhone"]),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// UI HELPERS
  Widget rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget quickAmountButton(String amount) {
    return InkWell(
      onTap: () {
        amountController.text = amount;
        setState(() {});
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("₹ $amount",
            style: const TextStyle(color: Colors.blue)),
      ),
    );
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Credit Card Payment"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🏦 CARD PROVIDER
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.billerName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            rowItem("Card Number", cardNumber),
            rowItem("Customer Name", customerName),

            const Divider(),

            GestureDetector(
              onTap: () =>
                  setState(() => showMoreDetails = !showMoreDetails),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bill Details",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Icon(showMoreDetails
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down)
                ],
              ),
            ),

            if (showMoreDetails) ...[
              const SizedBox(height: 10),
              rowItem("Total Amount", "₹ $billAmount"),
              rowItem("Minimum Due", "₹ $minAmount"),
              rowItem("Due Date", dueDate),
            ],

            const Divider(),

            const SizedBox(height: 14),

            const Text("Enter Amount"),
            const SizedBox(height: 8),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: "₹ ",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                quickAmountButton("1000"),
                quickAmountButton("2000"),
                quickAmountButton("5000"),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : processPayment,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text("Proceed to Pay"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}