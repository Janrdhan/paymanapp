import 'dart:convert';
//import 'dart:developer';
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
   final String customerType;
  const CreditCardBillersScreen({super.key,required this.phone, required this.customerType});

  @override
  _CreditCardBillersScreenState createState() => _CreditCardBillersScreenState();
}

class _CreditCardBillersScreenState extends State<CreditCardBillersScreen> {
  List<Biller> _billers = [];
  List<Biller> _filteredBillers = [];
  final TextEditingController _searchController = TextEditingController();
  //String _availableAmount = "0.00";
  //String _instantPayBalance = "0.00";
  bool _isLoading = true;
  String? _errorMessage;
  
   String _InstantPayAmount = "N/A";
   String _userWalletAmount = "N/A";
   bool? _billAvenue;

  @override
  void initState() {
    super.initState();
    _fetchBillers();
    getAvailableBalance();
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
        Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          if (data.containsKey("billers") && data["billers"] is List) {
            print("Parsed data: $data['billAvenue']");
            _billAvenue= data['billAvenue'];
            _billers = (data["billers"] as List)
                .map((json) => Biller.fromJson(json))
                .toList();
          } else {
            _billers = [];
          }

          _filteredBillers = _billers;
          _isLoading = false;
        });
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

  Future<void> getAvailableBalance() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${ApiHandler.baseUri}/Auth/GetPaymanAccountAmount");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _InstantPayAmount = data['instantpayamount'];
          _userWalletAmount = data['userwalletamount'];
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('Credit Card Billers'),
       actions: [
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Image.asset(
        "assets/images/Bharat Connect Primary Logo_PNG.png", // your BBPS logo path
        height: 40,
        width: 40,
      ),
    ),
  ],),
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
                     onTap: () async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    if (_billAvenue == true) {
      final url = Uri.parse('${ApiHandler.baseUri}/CCBill/CheckBillerCategory?billerId=${biller.billerId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (!mounted) return;
      Navigator.of(context).pop(); // remove loading dialog

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['isAvailable'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BillerDetailsScreen(
                biller: biller,
                phone: widget.phone,
                userWalletAmount: _userWalletAmount,
                instantPaysAmount: _InstantPayAmount,
                customerType: widget.customerType
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "This biller is not valid"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to validate biller: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      Navigator.of(context).pop(); // remove loading dialog if needed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillerDetailsScreen(
            biller: biller,
            phone: widget.phone,
            userWalletAmount: _userWalletAmount,
            instantPaysAmount: _InstantPayAmount,
            customerType: widget.customerType
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) Navigator.of(context).pop(); // remove loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error validating biller: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
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
