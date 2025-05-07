import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';

class NewUserDetailsScreen extends StatefulWidget {
  final String phone;
  const NewUserDetailsScreen({required this.phone,super.key});

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

  final List<String> _customerTypes = ['Distributor', 'Retailer'];
  final List<String> _margins = ['1.20', '1.30', '1.40','1.42','1.50'];

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

    final url = Uri.parse('${ApiHandler.baseUri1}/Users/CreateUser'); // Replace with your API

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "customerType": _selectedCustomerType,
        "margin": _selectedMargin,
        "isActive": _isActive,
      }),
    );

    setState(() => _isSubmitting = false);

    final responseData = json.decode(response.body);
    final isSuccess = response.statusCode == 200 && responseData['status'] == 'success';
    final message = responseData['message'] ?? (isSuccess ? 'User added successfully' : 'Something went wrong');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuccess ? 'Success' : 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (isSuccess) {
                Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) =>  DashboardScreen(phone: widget.phone)),
                  );
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("New User Details"),
        backgroundColor: Colors.blueAccent,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit', style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
