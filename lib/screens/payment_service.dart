import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  final String apiUrl = "https://srredu.in/PayIn/InitiatePayment";
  final String verifyUrl = "https://srredu.in/PayIn/VerifyPayment";

  Future<String?> getAccessKey(String phone, String holderNumber, String amount,String holderName, String holderEmail) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone,"amount":amount, "holderName": holderName,"holderEmail": holderEmail, "cardHolderNumber": holderNumber}),
      );

      print("🔍 AccessKey Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse["status"] == 1) {
          return jsonResponse["data"];
        }
      }
    } catch (e) {
      print("❌ Exception in getAccessKey: $e");
    }
    return null;
  }

 Future<Map<String, dynamic>> verifyPayment(
  String txnid,
  String phone,
  String cardNumber,
  String amount,
  String gateway,
  String holderName,
  String holderNumber,
  String holderEmail

) async {
  try {
    final response = await http.post(
      Uri.parse(verifyUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "txnid": txnid,
        "phone": phone,
        "cardNumber": cardNumber,
        "amount": amount,
        "gateway": gateway,
      }),
    );

    print("📩 VerifyPayment Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    print("❌ Exception in verifyPayment: $e");
  }

  return {"error": "Verification failed"};
}

}
