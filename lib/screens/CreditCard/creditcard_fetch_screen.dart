import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'creditcard_bill_details_screen.dart';

class CreditCardFetchScreen extends StatefulWidget {
  final String userPhone;
  final String billerId;
  final String billerName;
  final String billerLogoUrl;

  const CreditCardFetchScreen({
    super.key,
    required this.userPhone,
    required this.billerId,
    required this.billerName,
    required this.billerLogoUrl,
  });

  @override
  State<CreditCardFetchScreen> createState() =>
      _CreditCardFetchScreenState();
}

class _CreditCardFetchScreenState
    extends State<CreditCardFetchScreen> {
  final TextEditingController cardCtrl = TextEditingController();

  bool isLoading = false;
  String? validationError;

  /// ✅ VALIDATION
  bool validate() {
    final v = cardCtrl.text.trim();

    if (v.isEmpty || v.length < 8) {
      setState(() =>
          validationError = 'Please enter valid Card Number');
      return false;
    }

    setState(() => validationError = null);
    return true;
  }

  /// 🚀 FETCH BILL
  Future<void> onConfirm() async {
    if (!validate()) return;

    setState(() => isLoading = true);

    final url =
        Uri.parse('${ApiHandler.baseUri}/BillPayments/FetchBill');

    final body = {
      'billerId': widget.billerId,
      'serviceNumber': cardCtrl.text.trim(), // 🔥 CARD NUMBER
      'customerMobile': widget.userPhone,
      'userPhone': widget.userPhone,
    };

    debugPrint('CC Fetch request: ${jsonEncode(body)}');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);

        debugPrint('CC Fetch response: ${jsonEncode(jsonData)}');

        if (jsonData["status"] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreditCardBillDetailsScreen(
                billerId: widget.billerId,
                billerName: widget.billerName,
                billerLogoUrl: widget.billerLogoUrl,
                cardNumber: cardCtrl.text.trim(),
                userPhone: widget.userPhone,
                billData: jsonData,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(jsonData["message"] ?? "Unknown error")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch bill')),
        );
      }
    } catch (e) {
      debugPrint('FetchBill exception: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching bill')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🎯 INFO CARD
  Widget infoCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(widget.billerName),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🔹 INPUT
                  const Text(
                    'Credit Card Number',
                    style:
                        TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: cardCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter card number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: validationError,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 INFO
                  infoCard(
                    'Safe & Secure',
                    'We use encrypted connection to fetch your bill details securely.',
                  ),

                  const SizedBox(height: 12),

                  infoCard(
                    'Never miss payments',
                    'Get reminders for your credit card due dates.',
                  ),
                ],
              ),
            ),

            /// 🔻 BUTTON
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onConfirm,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Confirm'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}