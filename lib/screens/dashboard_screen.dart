import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/bank_list.dart';
import 'package:paymanapp/screens/payin.dart';
import 'package:paymanapp/screens/tokenvalidator.dart';
import 'package:paymanapp/screens/user_profile_screen.dart';
import 'package:paymanapp/screens/history_screen.dart';
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class DashboardScreen extends StatefulWidget {
  final String phone;
  const DashboardScreen({required this.phone, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  int _currentPage = 0;
  late final Timer _carouselTimer;
  Timer? _inactivityTimer;
  bool _isLoading = false;
  bool _payIn = false;
  bool _ccBill = false;

  final List<String> imagePaths = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  @override
  void initState() {
    super.initState();
    GetUserDetails();
    _pageController = PageController(viewportFraction: 0.85);
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= imagePaths.length) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    _resetInactivityTimer();
  }

  Future<void> GetUserDetails() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiHandler.baseUri1}/Users/Login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": widget.phone}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final userDetails = data['userDetails'];
        print(userDetails);
        setState(() {
          _payIn = userDetails['payIn'];
          _ccBill = userDetails['ccBill'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), _handleInactivity);
  }

  void _handleUserInteraction([_]) {
    _resetInactivityTimer();
  }

  void _handleInactivity() async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Timeout"),
        content: const Text("You have been idle for 5 minutes. Do you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Stay Logged In"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("Logout"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _resetInactivityTimer();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryScreen(phone: widget.phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TokenValidator(
      child: Listener(
        onPointerDown: _handleUserInteraction,
        onPointerMove: _handleUserInteraction,
        onPointerUp: _handleUserInteraction,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text('PAYMAN', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfileScreen(phone: widget.phone)),
                  );
                },
              ),
            ],
          ),
          body: _buildDashboardBody(),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildAccordionImages(),
          const SizedBox(height: 16),
          _buildServiceSection("Recharge & Bills", [
            'Mobile recharge',
            'FASTag recharge',
            'Mobile postpaid',
            'DTH recharge',
            'Broadband bill',
            'Landline bill',
            'Cable TV',
          ], [
            Icons.smartphone,
            Icons.directions_car,
            Icons.phone_android,
            Icons.satellite_alt,
            Icons.wifi,
            Icons.phone,
            Icons.tv,
          ]),
          _buildServiceSection("Utilities", [
            'Electricity bill',
            'LPG cylinder',
            'Water bill',
            'Piped gas',
            'Municipal services',
            'Municipal taxes',
            'Housing / apartment',
            'Clubs & association',
          ], [
            Icons.electrical_services,
            Icons.local_gas_station,
            Icons.water_drop,
            Icons.fireplace,
            Icons.apartment,
            Icons.house,
            Icons.business,
            Icons.groups,
          ]),
          if (_payIn || _ccBill) _buildServiceSection("Finance", _buildFinanceLabels(), _buildFinanceIcons()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<String> _buildFinanceLabels() {
    List<String> labels = [];
    if (_payIn) labels.add('Pay In');
    labels.add('Credit card');
    labels.add('Loan repayment');
    labels.add('LIC / insurance');
    labels.add('Recurring deposit');
    if (_ccBill) labels.add('CC Bill');
    return labels;
  }

  List<IconData> _buildFinanceIcons() {
    List<IconData> icons = [];
    if (_payIn) icons.add(Icons.arrow_downward);
    icons.add(Icons.credit_card);
    icons.add(Icons.savings);
    icons.add(Icons.verified_user);
    icons.add(Icons.calendar_today);
    if (_ccBill) icons.add(Icons.receipt_long);
    return icons;
  }

  Widget _buildAccordionImages() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePaths[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceSection(String title, List<String> labels, List<IconData> icons) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: labels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              bool isPopular = labels[index] == 'Pay In';
              return GestureDetector(
                onTap: () {
                  if (labels[index] == 'Pay In') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PayInScreen(phone: widget.phone)));
                  } else if (labels[index] == 'CC Bill') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreditCardBillersScreen(phone: widget.phone)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${labels[index]} tapped")),
                    );
                  }
                },
                child: Column(
                  children: [
                    if (isPopular)
                      const Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(icons[index], size: 26, color: Colors.purple),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
    );
  }
}
