// select_fastag_provider_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/widgets/api_handler.dart';
import 'fastag_fetch_screen.dart';

class SelectFastagProviderScreen extends StatefulWidget {
  final String userPhone;
  const SelectFastagProviderScreen({super.key, required this.userPhone});

  @override
  State<SelectFastagProviderScreen> createState() => _SelectFastagProviderScreenState();
}

class _SelectFastagProviderScreenState extends State<SelectFastagProviderScreen> {
  List<dynamic> allBillers = [];
  List<dynamic> filtered = [];
  List<dynamic> recents = []; // load/save from prefs if needed
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
          .replace(queryParameters: {'billerName': 'Fastag', 'userPhone': widget.userPhone});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        allBillers = (jsonData['billers'] ?? []) as List<dynamic>;
        filtered = List.from(allBillers);
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
        final id = (b['billerId'] ?? '').toString().toLowerCase();
        return name.contains(term) || cate.contains(term) || id.contains(term);
      }).toList();
    });
  }

  void openProvider(dynamic biller) async {
    
    // Save recent if you like...

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
        builder: (_) => FastagFetchScreen(
          userPhone: widget.userPhone,
          billerId: biller['billerId'].toString(),
          billerName: biller['billerName'] ?? '',
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.local_shipping, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b['billerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(b['billerId']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Provider'),
        leading: BackButton(),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: Image.asset('assets/images/Bharat Connect Primary Logo_PNG.png', height: 26)),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  // banner
                  Container(
                    height: 86,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.deepPurple.shade700, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Expanded(child: Text('Get flat ₹30 cashback\nOn FASTag payments', style: const TextStyle(color: Colors.white, fontSize: 16))),
                     // ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white), child: const Text('Pay now', style: TextStyle(color: Colors.black))),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // search
                  TextField(
                    controller: searchCtrl,
                    onChanged: onSearch,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by biller or id',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recents
                  if (recents.isNotEmpty) ...[
                    Align(alignment: Alignment.centerLeft, child: const Text('Recents', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    providerTile(recents.first),
                    const SizedBox(height: 12),
                  ],

                  Align(alignment: Alignment.centerLeft, child: const Text('All Billers', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),

                  Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (_, i) => providerTile(filtered[i]))),
                ]),
              ),
      ),
    );
  }
}
