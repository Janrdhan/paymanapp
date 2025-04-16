import 'dart:convert'; // ✅ For JSON parsing
import 'package:easebuzz_flutter/easebuzz_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException handling
import 'payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String cardNumber;
  final String mobileNumber;
  final String gatewayType;

  const PaymentScreen({
    super.key,
    required this.cardNumber,
    required this.mobileNumber,
    required this.gatewayType,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final EasebuzzFlutter _easebuzzFlutterPlugin = EasebuzzFlutter();
  String _paymentResponse = 'No payment response yet'; // ✅ Added missing variable

  Future<void> initiatePayment() async {
    String? accessKey = await _paymentService.getAccessKey();
    if (accessKey != null) {
      print("🛠 Access Key: $accessKey");

      String payMode = "test"; // Change to "production" for live

      try {
        final paymentResponse =
            await _easebuzzFlutterPlugin.payWithEasebuzz(accessKey, payMode);

      setState(() {
        // Convert the response to string and update _paymentResponse
        _paymentResponse = paymentResponse.toString();
      });

      if (paymentResponse != null) {
        try {

          RegExp regExp = RegExp(r'(SRREDU\d+)'); // Regex to match SRREDU followed by digits
         Match? match = regExp.firstMatch(_paymentResponse);

  if (match != null) {
    String extractedText = match.group(0)!; // Extract matched text
    print("✅ Extracted: $extractedText");

    // Now you can send it to API or use it as needed
    //sendPaymentResponse(extractedText);

          //String? status = await _paymentService.sendPaymentResponse(_paymentResponse);

    //       String formattedResponse = _paymentResponse
    // .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match.group(1)}":') // Fix missing quotes on keys
    // .replaceAll("'", "\"");
    
          // if (status == "success") {
          //   handlePaymentResponse(paymentResponse.toString());
          // } else {
          //   print("❌ Payment failed.");
          //   showResponseDialog("Payment Failed!");
          // }

          // ✅ Show response in dialog
        //   Map<String, dynamic> responseJson = jsonDecode(_paymentResponse);

        // // Extract the required fields
        // //String result = responseJson["result"] ?? "Unknown result";
        // String status = responseJson["payment_response"]["status"] ?? "Unknown status";
           showResponseDialog(extractedText);
  }
        } catch (e) {
          print("❌ Error decoding payment response: $e");
          showResponseDialog("Error decoding payment response.");
        }
      } else {
        print("❌ Payment failed: Response is null.");
        showResponseDialog("Payment Failed: No response received.");
      }
      } on PlatformException catch (e) {
        setState(() {
          _paymentResponse = jsonEncode({
            "message": "Payment failed",
            "error": e.message
          });
        });

        print("❌ Payment Error: ${e.message}");
        showResponseDialog(_paymentResponse);
      }
    } else {
      print("❌ Failed to get access key.");
      showResponseDialog("Error: Unable to get access key.");
    }
  }

  void handlePaymentResponse(String responseString) async {
    try {
      final Map<String, dynamic> response = jsonDecode(responseString);
      String status = response["status"] ?? "failed";
      String txnId = response["txnid"] ?? "";
      String message = response["message"] ?? "Unknown error";

      if (status == "success") {
        print("✅ Payment Successful! Transaction ID: $txnId");

        // ✅ Call the backend API to verify success
        await _paymentService.verifyPayment(context, txnId);

        // ✅ Show success message in AlertDialog
        showResponseDialog("Payment Successful! Transaction ID: $txnId");
      } else {
        print("❌ Payment Failed: $message");
        showResponseDialog("Payment Failed: $message");
      }
    } catch (e) {
      print("❌ Error parsing payment response: $e");
      showResponseDialog("Error processing payment response.");
    }
  }

  // ✅ Function to show response in an AlertDialog
  void showResponseDialog(String responseMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Response"),
          content: SingleChildScrollView(
            child: Text(responseMessage),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment Gateway")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("💳 Card Number: ${widget.cardNumber}"),
            Text("📞 Mobile Number: ${widget.mobileNumber}"),
            Text("💰 Gateway: ${widget.gatewayType}"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: initiatePayment,
              child: Text("🚀 Proceed to Pay"),
            ),
            SizedBox(height: 20),
            Text(_paymentResponse), // ✅ Show payment response
          ],
        ),
      ),
    );
  }
}
