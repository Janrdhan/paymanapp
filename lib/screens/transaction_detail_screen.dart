import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:paymanapp/widgets/api_handler.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final String transactionMode;

  const TransactionDetailScreen({super.key, required this.transactionId, required this.transactionMode});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Map<String, dynamic>? transaction;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  Future<void> _fetchTransactionDetails() async {
    final response = await http.get(
      Uri.parse('${ApiHandler.baseUri1}/HistoryScreen/GetTransactionDetails?id=${widget.transactionId}&&mode=${widget.transactionMode}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        transaction = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      // Optional: handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[600],
      appBar: AppBar(
        title: const Text('Transaction Successful'),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transaction == null
              ? const Center(child: Text('Transaction not found'))
              : Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paid to', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(child: Text("JR")),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction!['receiverName'] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                  Text(
                                    transaction!['vpa'] ?? 'N/A',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${transaction!['amount']}',
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: Colors.grey),
                        const Text("Transfer Details", style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("Transaction ID: ${transaction!['transactionId']}", style: TextStyle(color: Colors.white70)),
                        Text("Debited from: ${transaction!['account']}", style: TextStyle(color: Colors.white70)),
                        Text("UTR: ${transaction!['utr']}", style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        Center(child: Text("Powered by", style: TextStyle(color: Colors.grey[600]))),
                        Center(child: Text("UPI | Axis Bank", style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                  ),
                ),
    );
  }
}
