// electricity_bill_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/electricity/bill_details_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class ElectricityBillScreen extends StatefulWidget {
  final String phone;
  final String customerType;
  final String billerName;
  final String billerId;
  final String billerLogoUrl;

  const ElectricityBillScreen({
    super.key,
    required this.phone,
    required this.customerType,
    required this.billerName,
    required this.billerId,
    required this.billerLogoUrl,
  });

  @override
  State<ElectricityBillScreen> createState() => _ElectricityBillScreenState();
}

class _ElectricityBillScreenState extends State<ElectricityBillScreen> {
  final TextEditingController serviceCtrl = TextEditingController();
  bool isLoading = false;
  String? validationError;

  @override
  void dispose() {
    serviceCtrl.dispose();
    super.dispose();
  }

  bool validate() {
    final v = serviceCtrl.text.trim();
    if (v.isEmpty) {
      setState(() => validationError = 'Please enter valid Unique Service Number');
      return false;
    }
    setState(() => validationError = null);
    return true;
  }

  Future<void> onConfirm() async {
    if (!validate()) return;

    setState(() => isLoading = true);
    final url = Uri.parse('${ApiHandler.baseUri}/BillPayments/FetchBill');

    final body = {
      'billerId': widget.billerId,
      'serviceNumber': serviceCtrl.text.trim(),
      'customerMobile': widget.phone,
      'userPhone': widget.phone
    };

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Print for debugging
        debugPrint('FetchBill response: ${jsonEncode(jsonData)}');

        // Navigate to bill details screen with returned data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailsScreen(
              billerId: widget.billerId,
              billerName: widget.billerName,
              billerLogoUrl: widget.billerLogoUrl,
              serviceNumber: serviceCtrl.text.trim(),
              userPhone: widget.phone,
              billData: jsonData,
            ),
          ),
        );
      } else {
        debugPrint('FetchBill failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch bill.')));
      }
    } catch (e) {
      debugPrint('FetchBill exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching bill')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget infoCard(String title, String subtitle, {Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.grey))])),
        if (trailing != null) trailing,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billerName),
        leading: BackButton(),
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Image.asset('assets/bharat_connect.png', height: 26))],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Unique Service Number', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: serviceCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'Enter unique service number',
                    errorText: validationError,
                  ),
                ),
                const SizedBox(height: 12),

                // small info card about permission
                infoCard('By proceeding further, you allow PhonePe to fetch your current and future bills and remind you',
                    'Allow access to your text messages to fetch your bills and remind on time',
                    trailing: ElevatedButton(onPressed: () {}, child: const Text('Allow'))),

                const SizedBox(height: 12),

                // promotional / reminder card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Avoid missed bill payments and overdue charges', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text("We'll remind you when your bills are due", style: TextStyle(color: Colors.grey)),
                    ])),
                    const SizedBox(width: 12),
                    // small illustration placeholder
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.notifications_active, color: Colors.purple))
                  ]),
                ),
                const SizedBox(height: 40),
              ]),
            ),

            // bottom confirm bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onConfirm,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm'),
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
