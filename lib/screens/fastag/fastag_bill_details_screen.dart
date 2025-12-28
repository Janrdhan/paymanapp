import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/payment_failure_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

import '../payment_success_screen_mob.dart' show PaymentSuccessScreen;

class FastagBillDetailsScreen extends StatefulWidget { final String billerId; final String billerName; final String billerLogoUrl; final String vehicleNumber; final String userPhone; final Map<String, dynamic> billData; 

const FastagBillDetailsScreen({ super.key, required this.billerId, required this.billerName, required this.billerLogoUrl, required this.vehicleNumber, required this.userPhone, required this.billData, });

  @override
  State<FastagBillDetailsScreen> createState() =>
      _FastagBillDetailsScreenState();
}

class _FastagBillDetailsScreenState extends State<FastagBillDetailsScreen> {
  bool showMoreDetails = false;
  TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  // ----------------------------
  // Extract fields from API data
  // ----------------------------

  String get vehicleNumber {
    try {
      return widget.billData["inputParams"][0]["paramValue"] ?? "";
    } catch (_) {
      return "";
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

  String get walletBalance {
    try {
      final info = widget.billData["additionalInfo"];
      final found = info.firstWhere(
        (i) => i["infoName"].toString().toLowerCase().contains("wallet"),
        orElse: () => null,
      );
      return found?["infoValue"] ?? "";
    } catch (_) {
      return "";
    }
  }

  String get maxRechargeAmount {
    try {
      final info = widget.billData["additionalInfo"];
      final found = info.firstWhere(
        (i) => i["infoName"]
            .toString()
            .toLowerCase()
            .contains("maximum permissible recharge"),
        orElse: () => null,
      );
      return found?["infoValue"] ?? "";
    } catch (_) {
      return "";
    }
  }

  String get vehicleModel {
    try {
      final info = widget.billData["additionalInfo"];
      final found = info.firstWhere(
        (i) => i["infoName"].toString().toLowerCase().contains("model"),
        orElse: () => null,
      );
      return found?["infoValue"] ?? "";
    } catch (_) {
      return "";
    }
  }

  // Raw XML fields
  String get xml_additionalInfo =>
      widget.billData["adddditionalInfo"] ?? "";

  String get xml_billerResponse =>
      widget.billData["billerResponse1"] ?? "";

  String get xml_billFetchResponse =>
      widget.billData["billFetchResponse"] ?? "";

  // -------------------------------------

  @override
  void initState() {
    super.initState();
    amountController.text = billAmount; // default
  }

  Future<void> processPayment() async {
  setState(() => isLoading = true);

  final url = Uri.parse("${ApiHandler.baseUri}/BillPayments/ProcessBill");

  final body = {
    "billerId": widget.billerId,
    "param1": vehicleNumber,
    "phone": widget.userPhone,
    "amount": double.tryParse(amountController.text.trim()) ?? 0.0,
    "enquiryReferenceId": widget.billData["enquiryReferenceId"] ?? "",
    "billerResponse": xml_billerResponse,
    "adddditionalInfo": xml_additionalInfo,
    "billFetchResponse": xml_billFetchResponse,
    "holderMobile": vehicleNumber,
    "device": 'Mobile',
    "customerName": customerName,
    "lastFourDigits": vehicleNumber,
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
        debugPrint('FASTAG Fetch response: ${jsonEncode(data)}');
      if (data["success"] == true) {
        // SUCCESS → Navigate to success screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(phone: data["userPhone"],amount: data["amount"],userName: data["userName"],customerType: 'new',),
          ),
        );
      } else {
        // FAILURE → Navigate to failed screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailureScreen(phone: data["userPhone"]),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("FASTag Recharge"),
        leading: BackButton(),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: Image.asset('assets/images/Bharat Connect Primary Logo_PNG.png', height: 26)),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FASTag Provider Box
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/fastag.png",
                    height: 40, width: 40,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.billerName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 14),

            // Vehicle Number Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Vehicle Number",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(vehicleNumber,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),

            SizedBox(height: 10),

            Divider(),

            GestureDetector(
              onTap: () => setState(() => showMoreDetails = !showMoreDetails),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bill Details",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Icon(showMoreDetails
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down)
                ],
              ),
            ),

            if (showMoreDetails) ...[
              SizedBox(height: 10),

              rowItem("Customer Name", customerName),
              rowItem("FASTag Balance", "₹ $walletBalance"),
              rowItem("Vehicle Model", vehicleModel),
              rowItem("Max Recharge Amount", "₹ $maxRechargeAmount"),

              SizedBox(height: 10),
            ],

            Divider(),

            SizedBox(height: 14),

            Text("Enter Amount", style: TextStyle(fontSize: 14)),

            SizedBox(height: 8),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "₹ ",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                quickAmountButton("500"),
                quickAmountButton("1000"),
                quickAmountButton("2000"),
              ],
            ),

            SizedBox(height: 25),

            SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Text('Proceed to Pay'),
                  ),
                ),

            SizedBox(height: 20),

            // Show XML debug (optional)
            Text("Raw XML (Debug)", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(xml_additionalInfo),
            SizedBox(height: 10),
            Text(xml_billFetchResponse),
            SizedBox(height: 10),
            Text(xml_billerResponse),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
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
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("₹ $amount", style: TextStyle(color: Colors.blue)),
      ),
    );
  }
}
