import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/BillerDetailsScreen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class Biller {
  final String billerId;
  final String billerName;
  final String categoryKey;
  final String type;
  final String categoryName;
  final String coverageCity;
  final String coverageState;
  final int coveragePincode;
  final String updatedDate;
  final String billerStatus;
  final bool isAvailable;
  final String iconUrl;

  Biller({
    required this.billerId,
    required this.billerName,
    required this.categoryKey,
    required this.type,
    required this.categoryName,
    required this.coverageCity,
    required this.coverageState,
    required this.coveragePincode,
    required this.updatedDate,
    required this.billerStatus,
    required this.isAvailable,
    required this.iconUrl,
  });

  factory Biller.fromJson(Map<String, dynamic> json) {
    return Biller(
      billerId: json['billerId'] ?? '',
      billerName: json['billerName'] ?? '',
      categoryKey: json['categoryKey'] ?? '',
      type: json['Type'] ?? '',
      categoryName: json['CategoryName'] ?? '',
      coverageCity: json['CoverageCity'] ?? '',
      coverageState: json['CoverageState'] ?? '',
      coveragePincode: json['CoveragePincode'] ?? 0,
      updatedDate: json['UpdatedDate'] ?? '',
      billerStatus: json['BillerStatus'] ?? '',
      isAvailable: json['IsAvailable'] ?? false,
      iconUrl: json['iconUrl'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Biller(billerId: $billerId, billerName: $billerName, category: $categoryName, iconUrl: $iconUrl)';
  }
}

class CreditCardBillersScreen extends StatefulWidget {
   final String phone;
  const CreditCardBillersScreen({super.key,required this.phone});

  @override
  _CreditCardBillersScreenState createState() => _CreditCardBillersScreenState();
}

class _CreditCardBillersScreenState extends State<CreditCardBillersScreen> {
  List<Biller> _billers = [];
  List<Biller> _filteredBillers = [];
  final TextEditingController _searchController = TextEditingController();
  String _availableAmount = "0.00";
  String _instantPayBalance = "0.00";
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBillers();
    _searchController.addListener(_filterBillers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBillers() async {
    try {
      final response = await http.get(Uri.parse('${ApiHandler.baseUri}/CCBill/CreditCardBillers'));

      if (response.statusCode == 200) {
        debugger();
        Map<String, dynamic> data = json.decode(response.body);
        print("Parsed data: $data");

        setState(() {
          _availableAmount = data["AvailableAmount"]?.toString() ?? "0.00";
          _instantPayBalance = data["InstantPayBalance"]?.toString() ?? "0.00";
          debugger();

          if (data.containsKey("billers") && data["billers"] is List) {
            print("Parsed data: $data");
            _billers = (data["billers"] as List)
                .map((json) => Biller.fromJson(json))
                .toList();
                print("Parsed data: $_billers");
          } else {
            _billers = [];
          }

          _filteredBillers = _billers;
          _isLoading = false;
        });

        print("Parsed billers: $_billers");
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load billers. Please try again.";
        });
      }
    } catch (e) {
      print("Error fetching billers: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Something went wrong. Check your internet connection.";
      });
    }
  }

  void _filterBillers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBillers = _billers
          .where((biller) => biller.billerName.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Card Billers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Biller",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Available Balance: ₹$_availableAmount", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("InstantPay Balance: ₹$_instantPayBalance", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
         Expanded(
  child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _filteredBillers.isEmpty
              ? const Center(child: Text("No billers found."))
              : ListView.builder(
                  itemCount: _filteredBillers.length,
                  itemBuilder: (context, index) {
                    final biller = _filteredBillers[index];
                    return ListTile(
                      leading: biller.iconUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                biller.iconUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.credit_card,
                                      color: Colors.blue, size: 40);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(Icons.credit_card,
                              color: Colors.blue, size: 40),
                      title: Text(biller.billerName),
                      //subtitle: Text("Biller ID: ${biller.billerId}"),
                      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BillerDetailsScreen(biller: biller,phone: widget.phone),
    ),
  );
},
                    );
                  },
                ),
)

        ],
      ),
    );
  }
}
