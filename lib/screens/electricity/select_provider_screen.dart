import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/electricity/electricity_bill_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class SelectProviderScreen extends StatefulWidget {
  final String userPhone;

  const SelectProviderScreen({super.key, required this.userPhone});

  @override
  State<SelectProviderScreen> createState() => _SelectProviderScreenState();
}

class _SelectProviderScreenState extends State<SelectProviderScreen> {
  List<dynamic> allBillers = [];
  List<dynamic> filtered = [];
  List<dynamic> recents = [];

  bool isLoading = false;
  final TextEditingController searchCtrl = TextEditingController();

  Map<String, dynamic>? selectedBillerDetails;

  @override
  void initState() {
    super.initState();
    fetchBillers();
  }

  // 🔥 FETCH BILLERS API
  Future<void> fetchBillers() async {
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
          .replace(queryParameters: {
        'billerName': 'Electricity',
        'userPhone': widget.userPhone
      });

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);

        allBillers = (jsonData['billers'] ?? []) as List<dynamic>;
        filtered = List.from(allBillers);
      } else {
        debugPrint("API Error: ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }

    setState(() => isLoading = false);
  }

  // 🔍 SEARCH FUNCTION
  void onSearch(String q) {
    final term = q.toLowerCase().trim();

    if (term.isEmpty) {
      setState(() => filtered = List.from(allBillers));
      return;
    }

    setState(() {
      filtered = allBillers.where((b) {
        final name = (b['billerName'] ?? '').toLowerCase();
        final cate = (b['category'] ?? '').toLowerCase();
        return name.contains(term) || cate.contains(term);
      }).toList();
    });
  }

  // 🚀 OPEN PROVIDER → FETCH DETAILS → NAVIGATE
  void openProvider(dynamic biller) async {
    try {
      final uri =
          Uri.parse('${ApiHandler.baseUri}/BillPayments/CheckBillerCategory')
              .replace(queryParameters: {
        'billerId': biller['billerId'].toString(),
        'userPhone': widget.userPhone,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        selectedBillerDetails = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Details Error: $e");
    }

    // 👉 Navigate to Bill Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElectricityBillScreen(
          phone: widget.userPhone,
          customerType: 'PREPAID',
          billerName: biller['billerName'] ?? '',
          billerId: biller['billerId'].toString(),
          billerLogoUrl: biller['iconUrl'] ?? '',
        ),
      ),
    );
  }

  // 🎯 BILLER TILE UI
  Widget providerTile(dynamic b) {
    return InkWell(
      onTap: () => openProvider(b),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 🔶 ICON
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.flash_on, color: Colors.orange),
            ),

            const SizedBox(width: 12),

            // 🔶 TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['billerName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: ${b['billerId']}",
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
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
      backgroundColor: const Color(0xffF5F6FA),

      // 🔷 APP BAR
      appBar: AppBar(
        title: const Text("Select Electricity Provider"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/bharat_connect.png',
              height: 26,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          )
        ],
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // 🎁 BANNER
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Get flat ₹30 cashback\non electricity bill payments",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white),
                              child: const Text("Pay now",
                                  style: TextStyle(color: Colors.black)),
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔍 SEARCH
                    TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Search by biller",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔹 RECENTS
                    if (recents.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Recents",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      providerTile(recents.first),
                      const SizedBox(height: 8),
                    ],

                    // 🔹 ALL BILLERS
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text("All Billers",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // 📜 LIST
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No billers found"))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  providerTile(filtered[i]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}