// fastag_fetch_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'fastag_bill_details_screen.dart';

class FastagFetchScreen extends StatefulWidget {
  final String userPhone;
  final String billerId;
  final String billerName;
  final String billerLogoUrl;

  const FastagFetchScreen({
    super.key,
    required this.userPhone,
    required this.billerId,
    required this.billerName,
    required this.billerLogoUrl,
  });

  @override
  State<FastagFetchScreen> createState() => _FastagFetchScreenState();
}

class _FastagFetchScreenState extends State<FastagFetchScreen> {
  final TextEditingController vehicleCtrl = TextEditingController();
  bool isLoading = false;
  String? validationError;

  bool validate() {
    final v = vehicleCtrl.text.trim();
    if (v.isEmpty) {
      setState(() => validationError = 'Please enter valid Vehicle Number / Tag ID');
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
      'serviceNumber': vehicleCtrl.text.trim(),
      'customerMobile': widget.userPhone,
      'userPhone': widget.userPhone,
    };

    debugPrint('FASTAG Fetch request: ${jsonEncode(body)}');

    try {
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        debugPrint('FASTAG Fetch response: ${jsonEncode(jsonData)}');
        if(jsonData["status"] == true){
           // Navigate to details screen with returned data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FastagBillDetailsScreen(
              billerId: widget.billerId,
              billerName: widget.billerName,
              billerLogoUrl: widget.billerLogoUrl,
              vehicleNumber: vehicleCtrl.text.trim(),
              userPhone: widget.userPhone,
              billData: jsonData,
            ),
          ),
        );

        }else{
          ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(jsonData["message"] ?? "Unknown error")),
  );
        }

       
      } else {
        debugPrint('FetchBill failed: ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch FASTag bill')));
      }
    } catch (e) {
      debugPrint('FetchBill exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching FASTag bill')));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.billerName),
        leading: BackButton(),
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Image.asset('assets/images/Bharat Connect Primary Logo_PNG.png', height: 26))],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Vehicle Number / Tag ID', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: vehicleCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'Enter vehicle number or tag id',
                    errorText: validationError,
                  ),
                ),
                const SizedBox(height: 12),
                infoCard('By proceeding further, you allow us to fetch your current and future FASTag bills and remind you.', 'We will fetch your tag transactions and upcoming dues.', trailing: ElevatedButton(onPressed: () {}, child: const Text('Allow'))),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Avoid missed FASTag payments and penalties', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6), Text("We'll remind you when your FASTag balance is low", style: TextStyle(color: Colors.grey))])), const SizedBox(width: 12), Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.directions_car, color: Colors.purple))])),
                const SizedBox(height: 40),
              ]),
            ),

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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
