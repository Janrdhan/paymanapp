import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';

void main() {
  runApp(const MaterialApp(
    home: BillPaymentScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  State<BillPaymentScreen> createState() => _BharatConnectScreenState();
}

class _BharatConnectScreenState extends State<BillPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Total number of tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 148, 200, 242),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bharat Connect Billers',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              Image.asset(
                'assets/images/Bharat Connect Primary Logo_PNG.png',
                height: 32,
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Bharat Connect Biller'),
              Tab(text: 'Query Transaction'),
              Tab(text: 'Raise Complaint'),
              Tab(text: 'Check Complaint Status'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BharatConnectBillerTab(),
            QueryTransactionTab(),
            RaiseComplaintTab(),
            CheckComplaintStatusTab(),
          ],
        ),
      ),
    );
  }
}

// ================= Tab 1: Bharat Connect Biller =================

class BharatConnectBillerTab extends StatefulWidget {
  const BharatConnectBillerTab({super.key});

  @override
  State<BharatConnectBillerTab> createState() => _BharatConnectBillerTabState();
}

class _BharatConnectBillerTabState extends State<BharatConnectBillerTab> {
  List<dynamic> categories = [];
  List<String> creditCardBillers = ['Bank of Baroda test'];
  String? selectedCategory;
  String? selectedBiller;

  final lastFourController = TextEditingController();
  final registeredMobileController = TextEditingController();
  final customerMobileController = TextEditingController();
  final amountController = TextEditingController(text: "450.00");

  bool showInputs = false;
  bool billFetched = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse('https://paymanfintech.in/BillAvenue/GetCategories');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = data;
        });
      } else {
        // ignore: avoid_print
        print('Failed to load categories');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching categories: $e');
    }
  }

  void showPaymentConfirmationDialog() {
    final player = AudioPlayer();
    // Play sound without awaiting, so it starts instantly with dialog
    player.play(AssetSource('sounds/BharatConnect MOGO 270824.mp3'));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.all(0),
          contentPadding: const EdgeInsets.all(16),
          title: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Bharat Connect - Payment Confirmation",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/B Assured Logo_PNG.png', // B Assured logo
                  height: 50,
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Successful!\nThank you for your payment.",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/images/B Assured Logo_PNG.png', // Large B Assured display
                  height: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "We have received your payment request.\nPlease quote your Transaction Reference ID for any queries.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // your details table can be added here
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _ddDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  DropdownStyleData get _dropdownStyle => DropdownStyleData(
        maxHeight: 320,
        isOverButton: false, // ensure menu opens below, not covering the field
        offset: const Offset(0, 4), // tiny gap from the field
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          DropdownButtonFormField2<String>(
            isExpanded: true,
            value: selectedCategory,
            decoration: _ddDecoration("Select Biller Category"),
            hint: const Text("Select Biller Category"),
            items: categories.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item['value'].toString(),
                child: Text(item['text'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                selectedBiller = null;
                showInputs = false;
                billFetched = false;
              });
            },
            dropdownStyleData: _dropdownStyle,
            menuItemStyleData: const MenuItemStyleData(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          const SizedBox(height: 16),

          if (selectedCategory == "OU12BB000NATKB")
            DropdownButtonFormField2<String>(
              isExpanded: true,
              value: selectedBiller,
              decoration: _ddDecoration("Select Credit Card Biller"),
              hint: const Text("Select Credit Card Biller"),
              items: creditCardBillers.map((biller) {
                return DropdownMenuItem(
                  value: biller,
                  child: Text(biller),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBiller = value;
                  showInputs = true;
                  billFetched = false;
                });
              },
              dropdownStyleData: _dropdownStyle,
              menuItemStyleData: const MenuItemStyleData(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),

          const SizedBox(height: 16),

          if (showInputs) ...[
            TextField(
              controller: lastFourController,
              decoration: const InputDecoration(labelText: "Last 4 Digits of Card", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: registeredMobileController,
              decoration: const InputDecoration(labelText: "Registered Mobile", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customerMobileController,
              decoration: const InputDecoration(labelText: "Customer Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),

            if (billFetched) ...[
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ],

            const SizedBox(height: 20),

            if (!billFetched)
              ElevatedButton(
                onPressed: () {
                  // Implement real API call here if needed, then:
                  setState(() {
                    billFetched = true;
                  });
                },
                child: const Text("Fetch Bill"),
              ),
          ],

          const SizedBox(height: 20),

          if (billFetched) ...[
            const Text(
              "Biller Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Customer Name: Raj Kumar"),
            const Text("Bill Number: BILL789456"),
            const Text("Due Date: 2025-08-15"),
            const Text("Status: Pending"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: showPaymentConfirmationDialog,
              child: const Text("Process Payment"),
            ),
          ]
        ],
      ),
    );
  }
}

// ================= Tab 2: Query Transaction =================

class QueryTransactionTab extends StatefulWidget {
  const QueryTransactionTab({super.key});

  @override
  State<QueryTransactionTab> createState() => _QueryTransactionTabState();
}

class _QueryTransactionTabState extends State<QueryTransactionTab> {
  final mobileController = TextEditingController();
  final txnIdController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Check your transaction status using Mobile number or Transaction ID",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: mobileController,
            decoration: const InputDecoration(
              labelText: "Enter Mobile No",
              hintText: "Mobile number",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select From Date",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      fromDate != null
                          ? "${fromDate!.day.toString().padLeft(2, '0')}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.year}"
                          : "dd-mm-yyyy",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select To Date",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      toDate != null
                          ? "${toDate!.day.toString().padLeft(2, '0')}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.year}"
                          : "dd-mm-yyyy",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: txnIdController,
            decoration: const InputDecoration(
              labelText: "B-Connect TXN ID",
              hintText: "TXN ID",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add real API call here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Query submitted")),
                );
              },
              child: const Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Tab 3: Raise Complaint =================

class RaiseComplaintTab extends StatefulWidget {
  const RaiseComplaintTab({super.key});

  @override
  State<RaiseComplaintTab> createState() => _RaiseComplaintTabState();
}

class _RaiseComplaintTabState extends State<RaiseComplaintTab> {
  final mobileController = TextEditingController();
  final complaintDescriptionController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  String selectedComplaintType = "Service";
  String? selectedServiceReason;
  String? selectedDisposition;

  final List<String> serviceReasons = [
    'Transaction Failed',
    'Wrong Account Number',
    'Delayed Credit',
    'Invalid Biller',
  ];

  final List<String> complaintDispositions = [
    'Transaction Successful, Amount Debited but services not received',
    'Transaction Successful, Amount Debited but Service Disconnected or Service Stopped',
    'Transaction Successful, Amount Debited but Late Payment Surcharge Charges add in next bill',
    'Erroneously paid in wrong account',
    'Duplicate Payment',
    'Erroneously paid the wrong amount',
    'Payment information not received from Biller or Delay in receiving payment information from the Biller',
    'Bill Paid but Amount not adjusted or still showing due amount'
  ];

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  void _submitComplaint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Complaint Submitted")),
    );
  }

  InputDecoration _ddDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  DropdownStyleData get _dropdownStyle => DropdownStyleData(
        maxHeight: 320,
        isOverButton: false,
        offset: const Offset(0, 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Enter details to raise complaint",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: mobileController,
            decoration: const InputDecoration(
              labelText: "Mobile Number",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField2<String>(
            value: selectedComplaintType,
            isExpanded: true,
            decoration: _ddDecoration("Type of Complaint"),
            items: const [
              DropdownMenuItem(value: "Service", child: Text("Service")),
              DropdownMenuItem(value: "Technical", child: Text("Technical")),
            ],
            onChanged: (value) {
              setState(() {
                selectedComplaintType = value!;
              });
            },
            dropdownStyleData: _dropdownStyle,
            menuItemStyleData: const MenuItemStyleData(height: 44),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField2<String>(
            value: selectedDisposition,
            isExpanded: true,
            decoration: _ddDecoration("Complaint Disposition"),
            hint: const Text("Select"),
            items: complaintDispositions.map((disposition) {
              return DropdownMenuItem(
                value: disposition,
                child: Text(
                  disposition,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDisposition = value;
              });
            },
            dropdownStyleData: _dropdownStyle,
            menuItemStyleData: const MenuItemStyleData(height: 48),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select From Date",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      fromDate != null
                          ? "${fromDate!.day.toString().padLeft(2, '0')}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.year}"
                          : "dd-mm-yyyy",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select To Date",
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      toDate != null
                          ? "${toDate!.day.toString().padLeft(2, '0')}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.year}"
                          : "dd-mm-yyyy",
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField2<String>(
                  value: selectedServiceReason,
                  isExpanded: true,
                  decoration: _ddDecoration("Service Reason"),
                  hint: const Text("-- Select Service Reason --"),
                  items: serviceReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedServiceReason = value;
                    });
                  },
                  dropdownStyleData: _dropdownStyle,
                  menuItemStyleData: const MenuItemStyleData(height: 44),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: complaintDescriptionController,
                  decoration: const InputDecoration(
                    labelText: "Complaint Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitComplaint,
              child: const Text("Submit"),
            ),
          )
        ],
      ),
    );
  }
}

// ================= Tab 4: Check Complaint Status =================

class CheckComplaintStatusTab extends StatefulWidget {
  const CheckComplaintStatusTab({super.key});

  @override
  State<CheckComplaintStatusTab> createState() => _CheckComplaintStatusTabState();
}

class _CheckComplaintStatusTabState extends State<CheckComplaintStatusTab> {
  final complaintIdController = TextEditingController();
  String selectedComplaintType = "Service Request";

  bool showResult = false;
  final String dummyAssignedTo = "Support Team";
  final String dummyStatus = "In Progress";

  void _checkStatus() {
    setState(() {
      showResult = true;
    });
  }

  InputDecoration _ddDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  DropdownStyleData get _dropdownStyle => DropdownStyleData(
        maxHeight: 320,
        isOverButton: false,
        offset: const Offset(0, 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Check complaint status using Complaint ID",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: complaintIdController,
                  decoration: const InputDecoration(
                    labelText: "Complaint ID",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  value: selectedComplaintType,
                  decoration: _ddDecoration("Type of Complaint"),
                  items: const [
                    DropdownMenuItem(
                      value: "Service Request",
                      child: Text("Service Request"),
                    ),
                    DropdownMenuItem(
                      value: "Technical Issue",
                      child: Text("Technical Issue"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedComplaintType = value!;
                    });
                  },
                  dropdownStyleData: _dropdownStyle,
                  menuItemStyleData: const MenuItemStyleData(height: 44),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkStatus,
              child: const Text("Submit"),
            ),
          ),

          const SizedBox(height: 30),

          if (showResult) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Complaint Status Result",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(TextSpan(
                    text: "Complaint Assigned To: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: dummyAssignedTo,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  )),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(
                    text: "Complaint ID: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: complaintIdController.text,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  )),
                  const SizedBox(height: 6),
                  Text.rich(TextSpan(
                    text: "Status: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: dummyStatus,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
