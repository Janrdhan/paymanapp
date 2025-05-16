import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:paymanapp/screens/transaction_detail_screen.dart';
import 'dart:convert';

import 'package:paymanapp/widgets/api_handler.dart';

class HistoryScreen extends StatefulWidget {
  final String phone;
  const HistoryScreen({super.key, required this.phone});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final response = await http.get(
      Uri.parse('${ApiHandler.baseUri1}/HistoryScreen/GetTransactions?phone=${widget.phone}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _history = json.decode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No history found.'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final isPayIn = item['mode'] == 'PayIn';
                    final modeColor = isPayIn ? Colors.green : Colors.red;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Icon(
                          Icons.account_balance_wallet,
                          color: modeColor,
                        ),
                        title: Text(
                          '₹${item['amount']} - ${item['mode']}',
                          style: TextStyle(
                            color: modeColor.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Date: ${DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(item['created']))}',
                        ),
                        trailing: Text(
                          item['status'] == true ? "Success" : "Failed",
                          style: TextStyle(
                            color: item['status'] == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                transactionId: item['txnId'],
                                transactionMode: item['mode'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
