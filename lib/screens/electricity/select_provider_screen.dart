// select_provider_screen.dart
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
  List<dynamic> recents = []; // you could save/load recents from prefs
  bool isLoading = false;
  final TextEditingController searchCtrl = TextEditingController();
  Map<String, dynamic>? selectedBillerDetails;

  @override
  void initState() {
    super.initState();
    fetchBillers();
  }

  Future<void> fetchBillers() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('${ApiHandler.baseUri}/BillPayments/BillersList')
          .replace(queryParameters: {'billerName': 'Electricity', 'userPhone': widget.userPhone});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        // API returns object with .billers
        allBillers = (jsonData['billers'] ?? []) as List<dynamic>;
        filtered = List.from(allBillers);
        // Optionally set recents based on logic
      } else {
        debugPrint('BillersList error: ${res.body}');
      }
    } catch (e) {
      debugPrint('fetchBillers error: $e');
    }
    setState(() => isLoading = false);
  }

  void onSearch(String q) {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) {
      setState(() => filtered = List.from(allBillers));
      return;
    }
    setState(() {
      filtered = allBillers.where((b) {
        final name = (b['billerName'] ?? '').toString().toLowerCase();
        final cate = (b['category'] ?? '').toString().toLowerCase();
        return name.contains(term) || cate.contains(term);
      }).toList();
    });
  }

  void openProvider(dynamic biller) async {
    // push to service number screen, pass biller info & userPhone
     try {
      final uri =
          Uri.parse('${ApiHandler.baseUri}/BillPayments/CheckBillerCategory')
              .replace(queryParameters: {
        'billerId': biller['billerId'],
        'userPhone': widget.userPhone,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          selectedBillerDetails = data;
        });

        print("Biller details loaded: $data");
      }
    } catch (e) {
      print("Error loading biller details: $e");
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElectricityBillScreen(
          phone: widget.userPhone,
          customerType: 'PREPAID',
          billerName: biller['billerName'] ?? '',
          billerId: biller['billerId'] ?? biller['billerId'].toString(),
          billerLogoUrl: biller['iconUrl'] ?? '',
        ),
      ),
    );
  }

  Widget providerTile(dynamic b) {
    return InkWell(
      onTap: () => openProvider(b),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // placeholder circular icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(child: Icon(Icons.flash_on, color: Colors.orange)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['billerName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(b['billerId'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.more_vert, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Provider'),
        leading: BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset('assets/bharat_connect.png', height: 26), // optional
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
                    // banner
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(child: Text('Get flat ₹30 cashback\nOn electricity bill payments', style: const TextStyle(color: Colors.white, fontSize: 16))),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white), child: const Text('Pay now', style: TextStyle(color: Colors.black))),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search box
                    TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by biller',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recents title + list (if any)
                    if (recents.isNotEmpty) ...[
                      Align(alignment: Alignment.centerLeft, child: const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Recents', style: TextStyle(fontWeight: FontWeight.bold)))),
                      // show first recent
                      providerTile(recents.first),
                      const SizedBox(height: 8),
                    ],

                    // Section title
                    Align(alignment: Alignment.centerLeft, child: const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('All Billers', style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => providerTile(filtered[i]),
                        shrinkWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
