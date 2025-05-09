import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class PayOutHistoryScreen extends StatefulWidget {
  final String phone;
  const PayOutHistoryScreen({super.key, required this.phone});

  @override
  State<PayOutHistoryScreen> createState() => _PayOutHistoryScreenState();
}

class _PayOutHistoryScreenState extends State<PayOutHistoryScreen> {
  List<dynamic> _payOutList = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _loading = false;

  Future<void> _fetchPayOutHistory() async {
    setState(() => _loading = true);

    try {
      final url = Uri.parse("${ApiHandler.baseUri1}/PayIn/GetPayOutHistory");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": widget.phone,
          "startDate": _startDate.toIso8601String(),
          "endDate": _endDate.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _payOutList = data['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchPayOutHistory();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPayOutHistory();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayOut History'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payOutList.isEmpty
              ? const Center(child: Text("No payout history found."))
              : ListView.builder(
                  itemCount: _payOutList.length,
                  itemBuilder: (context, index) {
                    final item = _payOutList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 5.0,
                      child: ListTile(
                        title: Text("₹${item['amount']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Transaction ID: ${item['refId']}"),
                            Text("Account Number: ${item['accountNo']}"),
                            Text("Ifsc Code: ${item['ifscCode']}"),
                             Text("Account Holder Name: ${item['accountHolderName']}"),
                            Text("Mobile: ${item['userPhone']}"),
                            Text("PayOut Commission: ₹${item['payoutCommission']}"),
                            Text("Status: ${item['status']}"),
                            Text("Created: ${dateFormat.format(DateTime.parse(item['createdDate']))}"),
                          ],
                        ),
                        trailing: Text(
                          item['status'] ==true ? 'Sucess' : 'Failed',
                          style: TextStyle(
                            color: item['status'] == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
