import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final String transactionMode;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.transactionMode,
  });

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
    final url = Uri.parse(
      '${ApiHandler.baseUri1}/HistoryScreen/GetTransactionDetails'
      '?txnId=${Uri.encodeComponent(widget.transactionId)}&mode=${Uri.encodeComponent(widget.transactionMode)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          transaction = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print('Error fetching transaction: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color darkGreen = Colors.green.shade700;

    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: darkGreen,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transaction == null
              ? const Center(child: Text('Transaction not found', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid to', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transaction!['phone'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      transaction!['vpa'] ?? 'N/A',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${transaction!['amount'] ?? '0.00'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30, color: Colors.grey),
                          const Text(
                            "Transfer Details",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _detailRow("Transaction ID", transaction!['transactionId']),
                          _detailRow("Credited From", transaction!['account']),
                          _detailRow("Type", transaction!['type']),
                          _detailRow(
                            "Date",
                            _formatDate(transaction!['date']),
                          ),
                          _detailRow(
                            "Status",
                            transaction!['status'] ?? 'N/A',
                            color: _getStatusColor(transaction!['status']),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                Text("Powered by", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 4),
                                Text("Pay Man", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _detailRow(String title, String? value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text("$title:", style: const TextStyle(color: Colors.white70))),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(dateStr ?? ''));
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.white;
    final statusLower = status.toLowerCase();
    if (statusLower == 'success' || statusLower == 'completed') return Colors.green;
    if (statusLower == 'failed' || statusLower == 'error') return Colors.red;
    return Colors.orange;
  }
}
