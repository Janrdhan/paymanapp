import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'bbps_fetch_screen.dart';

class BBPSBillersScreen extends StatefulWidget {
  final String category;
  final String userPhone;

  const BBPSBillersScreen({
    super.key,
    required this.category,
    required this.userPhone,
  });

  @override
  State<BBPSBillersScreen> createState() => _BBPSBillersScreenState();
}

class _BBPSBillersScreenState extends State<BBPSBillersScreen> {
  List billers = [];

  @override
  void initState() {
    super.initState();
    fetchBillers();
  }

  Future<void> fetchBillers() async {
    final res = await http.get(
      Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
          .replace(queryParameters: {
        "billerName": widget.category,
        "userPhone": widget.userPhone,
      }),
    );

    final data = jsonDecode(res.body);
    setState(() => billers = data["billers"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: ListView.builder(
        itemCount: billers.length,
        itemBuilder: (_, i) {
          final b = billers[i];
          return ListTile(
            title: Text(b['billerName']),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BBPSFetchScreen(
                  biller: b,
                  userPhone: widget.userPhone,
                  category: widget.category,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}