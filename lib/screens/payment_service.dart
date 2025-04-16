import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ Import Material for Dialog
import 'package:http/http.dart' as http;

class PaymentService {
  final String apiUrl = "https://srredu.in/PayIn/InitiatePayment";
  final String verifyUrl = "https://srredu.in/PayIn/VerifyPayment";
  final String processPaymentUrl = "https://srredu.in/PayIn/ProcessPayment";

  Future<String?> getAccessKey() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("body: ${response.body}"); // Debugging

        if (jsonResponse["status"] == 1) {
          return jsonResponse["data"];  // ✅ Extract access key from "data"
        } else {
          print("Failed to get access key: ${response.body}");
          return null;
        }
      } else {
        print("Failed to get access key: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> verifyPayment(BuildContext context, String txnId) async {
    try {
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"txnid": txnId}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // ✅ Show response in an alert dialog
        showResponseDialog(context, jsonResponse);

      } else {
        print("❌ Error verifying payment: ${response.body}");
        
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }



  Future<String?> sendPaymentResponse(String paymentResponse) async {
    try {
      final response = await http.post(
        Uri.parse(processPaymentUrl),
        headers: {"Content-Type": "application/json"},
        body: paymentResponse,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        return jsonResponse['status'];

      } else {
        print("❌ Error verifying payment: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception: $e");
      return null;
    }
  }

  // ✅ Function to Show JSON Response in Alert Dialog
  void showResponseDialog(BuildContext context, Map<String, dynamic> jsonResponse) {
    String formattedJson = const JsonEncoder.withIndent("  ").convert(jsonResponse);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Response"),
          content: SingleChildScrollView(
            child: Text(formattedJson),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
