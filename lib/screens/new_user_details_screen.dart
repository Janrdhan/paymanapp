import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class NewUserDetailsScreen extends StatefulWidget {
  final String phone;
  final bool isAdmin;
  final Map<String, dynamic>? userData;

  const NewUserDetailsScreen({
    required this.phone,
    required this.isAdmin,
    this.userData,
    super.key,
  });

  @override
  State<NewUserDetailsScreen> createState() => _NewUserDetailsScreenState();
}

class _NewUserDetailsScreenState extends State<NewUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCustomerType;
  String? _selectedMargin;
  bool _isActive = false;
  bool _isSubmitting = false;

  bool? _payIn = false;
  bool? _payOut = false;
  bool? _ccBill = false;

  final List<String> _customerTypes = ['Distributor', 'Retailer'];
  final List<String> _margins = ['1.20', '1.30', '1.40', '1.42', '1.50'];

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      final user = widget.userData!;
      _firstNameController.text = user['firstName'] ?? '';
      _lastNameController.text = user['lastName'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';

      final customerType = user['customerType']?.toString();
      if (_customerTypes.contains(customerType)) {
        _selectedCustomerType = customerType;
      }

      final marginStr = user['margin']?.toString();
      if (_margins.contains(marginStr)) {
        _selectedMargin = marginStr;
      }

      _isActive = user['isActive'] == true;

      if (widget.isAdmin) {
        _payIn = user['payIn'] == true;
        _payOut = user['payOut'] == true;
        _ccBill = user['ccBill'] == true;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final isEdit = widget.userData != null;
    final url = isEdit
        ? Uri.parse('${ApiHandler.baseUri1}/Users/UpdateUser')
        : Uri.parse('${ApiHandler.baseUri1}/Users/CreateUser');

    final body = {
      "firstName": _firstNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "customerType": _selectedCustomerType,
      "margin": _selectedMargin,
      "isActive": _isActive,
    };

    if (widget.isAdmin) {
      body["payIn"] = _payIn;
      body["payOut"] = _payOut;
      body["ccBill"] = _ccBill;
    }

    if (isEdit) {
      body["id"] = widget.userData!["id"];
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      setState(() => _isSubmitting = false);

      final responseData = json.decode(response.body);
      final isSuccess = response.statusCode == 200 && responseData['status'] == 'success';
      final message = responseData['message'] ?? (isSuccess ? 'User saved successfully' : 'Something went wrong');

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => DashboardScreen(phone: widget.phone)),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (error) {
      setState(() => _isSubmitting = false);
      print("Error: $error");
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred while updating the user.'),
        ),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (value) => value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit User" : "New User Details"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_firstNameController, 'First Name'),
              const SizedBox(height: 12),
              _buildTextField(_lastNameController, 'Last Name'),
              const SizedBox(height: 12),
              _buildTextField(
                _emailController,
                'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(value)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _phoneController,
                'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.length != 10) return 'Enter 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown('Customer Type', _customerTypes, _selectedCustomerType,
                  (value) => setState(() => _selectedCustomerType = value)),
              const SizedBox(height: 12),
              _buildDropdown('Margin', _margins, _selectedMargin,
                  (value) => setState(() => _selectedMargin = value)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Is Active"),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 12),
              if (widget.isAdmin) ...[
                SwitchListTile(
                  title: const Text('Pay In'),
                  value: _payIn ?? false,
                  onChanged: (value) => setState(() => _payIn = value),
                ),
                SwitchListTile(
                  title: const Text('Pay Out'),
                  value: _payOut ?? false,
                  onChanged: (value) => setState(() => _payOut = value),
                ),
                SwitchListTile(
                  title: const Text('CC Bill'),
                  value: _ccBill ?? false,
                  onChanged: (value) => setState(() => _ccBill = value),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Update' : 'Submit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
