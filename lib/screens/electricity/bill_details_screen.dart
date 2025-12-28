// bill_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class BillDetailsScreen extends StatefulWidget {
  final String billerId;
  final String billerName;
  final String billerLogoUrl;
  final String serviceNumber;
  final String userPhone;
  final Map<String, dynamic> billData; // fetched bill JSON

  const BillDetailsScreen({
    super.key,
    required this.billerId,
    required this.billerName,
    required this.billerLogoUrl,
    required this.serviceNumber,
    required this.userPhone,
    required this.billData,
  });

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  bool isProcessing = false;
  bool autoPay = false;

  String getAmount() {
    // try various keys
    return widget.billData['billAmount']?.toString() ??
        widget.billData['amount']?.toString() ??
        widget.billData['amountDue']?.toString() ??
        '0';
  }

  String getCustomerName() {
    return widget.billData['customerName'] ?? widget.billData['name'] ?? '';
  }

  String getDueDate() {
    return widget.billData['dueDate'] ?? widget.billData['billDate'] ?? '';
  }

  String getReferenceId() {
    return widget.billData['referenceId'] ?? widget.billData['billRefId'] ?? widget.billData['billNumber'] ?? '';
  }

  Future<void> processPayment() async {
    setState(() => isProcessing = true);

    final url = Uri.parse('${ApiHandler.baseUri}/BillPayments/ProcessPayment');
    final body = {
      'billerId': widget.billerId,
      'serviceNumber': widget.serviceNumber,
      'customerMobile': widget.userPhone,
      'billAmount': getAmount(),
      'billReferenceId': getReferenceId(),
      'userPhone': widget.userPhone,
      'autoPay': autoPay.toString(),
    };

    debugPrint('ProcessPayment request: ${jsonEncode(body)}');

    try {
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      debugPrint('ProcessPayment response: ${res.body}');
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Payment Status'),
            content: Text(j['message'] ?? 'Payment successful'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Payment Failed'),
            content: Text('Unable to process payment.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      debugPrint('processPayment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error processing payment')));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Widget amountCard() {
    final amt = getAmount();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(getCustomerName(), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Bill Date : ${widget.billData['billDate'] ?? ''}', style: const TextStyle(color: Colors.grey)),
          ]),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₹ $amt', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Due Date: ${getDueDate()}', style: const TextStyle(color: Colors.red)),
            ]),
            // optional last paid info small text
            Column(children: [Text(''), Text('')]),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Last paid ₹${widget.billData['lastPaid'] ?? ''} on ${widget.billData['lastPaidDate'] ?? ''}', style: const TextStyle(color: Colors.grey)),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: ListView(children: [
            // header with biller logo and id
            Row(children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade100), child: const Icon(Icons.flash_on, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.billerName, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(widget.billerId, style: const TextStyle(color: Colors.grey))])),
            ]),
            const SizedBox(height: 16),

            // bill details card
            amountCard(),
            const SizedBox(height: 16),

            // autopay option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Checkbox(value: autoPay, onChanged: (v) => setState(() => autoPay = v ?? false)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Pay future bills with AUTOPAY\nWe\'ll remember and automatically pay your future bills on time', style: TextStyle(color: Colors.grey))),
              ]),
            ),
            const SizedBox(height: 40),
            // debug json (optional)
            Text('Raw response', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(const JsonEncoder.withIndent('  ').convert(widget.billData)),
            const SizedBox(height: 100),
          ]),
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isProcessing ? null : processPayment,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Proceed To Pay', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
