import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class UserTransactionScreen extends StatefulWidget {
  final String phone;

  const UserTransactionScreen({super.key, required this.phone});

  @override
  State<UserTransactionScreen> createState() => _UserTransactionScreenState();
}

class _UserTransactionScreenState extends State<UserTransactionScreen> {
  bool _isLoading = true;
  String _availableBalance = "";
  List<dynamic> _payIns = [];
  List<dynamic> _payOuts = [];

   final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    fetchUserHistory();
  }

  Future<void> fetchUserHistory() async {
    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/PayIn/GetUserHistory?phone=${widget.phone}');
      final response = await http.get(url);

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _availableBalance = data['availableBalance'] ?? [];
          _payIns = data['payInHistory'] ?? [];
          _payOuts = data['payOutHistory'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch user history');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Widget buildTransactionTile(dynamic txn, Color color) {
    return ListTile(
      leading: Icon(Icons.account_balance_wallet, color: color),
      title: Text("₹ ${txn['amount']}"),
      subtitle: Text("Ref: ${txn['ref']} • Date: ${txn['date'] != null ? dateFormat.format(DateTime.parse(txn['date'])) : 'N/A'}"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions - ${widget.phone}"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.lightGreen.shade100,
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                      title: const Text("Available Balance"),
                      subtitle: Text("₹ $_availableBalance", style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("PayIn History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  if (_payIns.isEmpty)
                    const Text("No PayIn history available")
                  else
                    ..._payIns.map((txn) => buildTransactionTile(txn, Colors.green)),
                  const SizedBox(height: 20),
                  const Text("PayOut History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  if (_payOuts.isEmpty)
                    const Text("No PayOut history available")
                  else
                    ..._payOuts.map((txn) => buildTransactionTile(txn, Colors.red)),
                ],
              ),
            ),
    );
  }
}
