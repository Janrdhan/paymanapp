import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';

class PayInHistoryScreen extends StatefulWidget {
  final String phone;
  const PayInHistoryScreen({super.key, required this.phone});

  @override
  State<PayInHistoryScreen> createState() => _PayInHistoryScreenState();
}

class _PayInHistoryScreenState extends State<PayInHistoryScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<dynamic> _transactions = [];

  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchPayInHistory();
    }
  }

  Future<void> _fetchPayInHistory() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${ApiHandler.baseUri1}/PayIn/GetPayInHistory");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": widget.phone,
          "startDate": _startDate.toIso8601String(),
          "endDate": _endDate.toIso8601String(),
        }),
      );

      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        setState(() {
          _transactions = json['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? "Error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPayInHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PayIn History"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text("No transactions found"))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "₹${txn['amount']}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  txn['status'] == true ? 'Sucess' : 'Failed',
                                  style: TextStyle(
                                    color: txn['status'] == true ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Txn ID: ${txn['easePayId'] ?? 'N/A'}"),
                            Text("Card Number: ${txn['cardNumber'] ?? 'N/A'}"),
                            Text("Mobile: ${txn['userPhone'] ?? 'N/A'}"),
                            Text("Email: ${txn['email'] ?? 'N/A'}"),
                            Text("PayIn Commission: ₹${txn['payInCommission'] ?? 0}"),
                            Text("Created Date: ${txn['createdDate'] != null ? dateFormat.format(DateTime.parse(txn['createdDate'])) : 'N/A'}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
