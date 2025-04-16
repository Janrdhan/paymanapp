import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      billerId: json['BillerId'] ?? '',
      billerName: json['BillerName'] ?? '',
      categoryKey: json['CategoryKey'] ?? '',
      type: json['Type'] ?? '',
      categoryName: json['CategoryName'] ?? '',
      coverageCity: json['CoverageCity'] ?? '',
      coverageState: json['CoverageState'] ?? '',
      coveragePincode: json['CoveragePincode'] ?? 0,
      updatedDate: json['UpdatedDate'] ?? '',
      billerStatus: json['BillerStatus'] ?? '',
      isAvailable: json['IsAvailable'] ?? false,
      iconUrl: json['IconUrl'] ?? '',
    );
  }
}


class CreditCardBillersScreen extends StatefulWidget {
  @override
  _CreditCardBillersScreenState createState() => _CreditCardBillersScreenState();
}

class _CreditCardBillersScreenState extends State<CreditCardBillersScreen> {
  List<Biller> _billers = [];
  List<Biller> _filteredBillers = [];
  TextEditingController _searchController = TextEditingController();
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

  Future<void> _fetchBillers() async {
  try {
    final response = await http.get(Uri.parse('https://localhost:44384/CCBill/CreditCardBillers'));

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);

      print("Parsed Data: $data");

      if (data.containsKey("billers")) {
        print("billers Count: ${data["billers"].length}");
      }

      setState(() {
        _availableAmount = data["AvailableAmount"]?.toString() ?? "0.00";
        _instantPayBalance = data["InstantPayBalance"]?.toString() ?? "0.00";

        if (data.containsKey("billers") && data["billers"] is List) {
          _billers = (data["billers"] as List)
              .map((json) => Biller.fromJson(json))
              .toList();
        } else {
          _billers = [];
        }

        _filteredBillers = _billers;
        _isLoading = false;
      });

      print("Billers after parsing: $_billers");
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
      _filteredBillers = _billers.where((biller) => biller.billerName.toLowerCase().contains(query)).toList();
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
                ? const Center(child: CircularProgressIndicator()) // 🔹 Show loader while fetching
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredBillers.isEmpty
                        ? const Center(child: Text("No billers found."))
                        : ListView.builder(
                            itemCount: _filteredBillers.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const Icon(Icons.credit_card, color: Colors.blue),
                                title: Text(_filteredBillers[index].billerName),
                                subtitle: Text("Biller ID: ${_filteredBillers[index].billerId}"),
                                onTap: () {
                                  print('Selected: ${_filteredBillers[index].billerName}');
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
