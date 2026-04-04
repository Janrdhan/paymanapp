import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/CreditCard/creditcard_fetch_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class SelectCreditCardProviderScreen extends StatefulWidget {
  final String userPhone;

  const SelectCreditCardProviderScreen({
    super.key,
    required this.userPhone,
  });

  @override
  State<SelectCreditCardProviderScreen> createState() =>
      _SelectCreditCardProviderScreenState();
}

class _SelectCreditCardProviderScreenState
    extends State<SelectCreditCardProviderScreen> {
  List<dynamic> allBillers = [];
  List<dynamic> filtered = [];
  bool isLoading = false;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBillers();
  }

  /// 🔥 FETCH CREDIT CARD BILLERS
  Future<void> fetchBillers() async {
    setState(() => isLoading = true);

    try {
      final uri =
          Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
              .replace(queryParameters: {
        'billerName': 'CreditCard', // ⚠️ IMPORTANT
        'userPhone': widget.userPhone,
      });

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        allBillers = jsonData['billers'] ?? [];
        filtered = List.from(allBillers);
      } else {
        debugPrint("API Error: ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }

    setState(() => isLoading = false);
  }

  /// 🔍 SEARCH
  void onSearch(String q) {
    final term = q.toLowerCase();

    setState(() {
      filtered = allBillers.where((b) {
        final name = (b['billerName'] ?? '').toLowerCase();
        return name.contains(term);
      }).toList();
    });
  }

  /// 🚀 OPEN PROVIDER
  void openProvider(dynamic biller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardFetchScreen(
          userPhone: widget.userPhone,
          billerId: biller['billerId'].toString(),
          billerName: biller['billerName'] ?? '',
          billerLogoUrl: biller['iconUrl'] ?? '',
        ),
      ),
    );
  }

  /// 🎯 TILE
  Widget providerTile(dynamic b) {
    return InkWell(
      onTap: () => openProvider(b),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.credit_card, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['billerName'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b['billerId'].toString(),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Select Credit Card Provider"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [

                  /// 🎁 BANNER
                  Container(
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Pay your credit card bills\nwith exciting cashback",
                        style:
                            TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔍 SEARCH
                  TextField(
                    controller: searchCtrl,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search credit card",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// LIST
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text("No providers found"))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                providerTile(filtered[i]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}