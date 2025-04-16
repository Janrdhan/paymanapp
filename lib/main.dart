//import 'dart:io'; // ✅ Import for HttpOverrides
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymanapp/screens/dashboard_screen.dart';
import 'package:paymanapp/screens/login_screen.dart';
import 'package:paymanapp/widgets/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //HttpOverrides.global = MyHttpOverrides();  // 🔥 Allow invalid SSL (for testing)

  bool isValidToken = await checkTokenValidity(); // ✅ Await token check before launching app

  runApp(MyApp(isValidToken: isValidToken));
}

class MyApp extends StatelessWidget {
  final bool isValidToken;

  const MyApp({super.key, required this.isValidToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isValidToken ? DashboardScreen() : LoginScreen(),
    );
  }
}

// ✅ Custom SSL Overrides (Allow Self-Signed SSL Certs for Testing)
// class MyHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     return super.createHttpClient(context)
//       ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//   }
// }

// ✅ Function to check if the stored JWT token is valid
Future<bool> checkTokenValidity() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token"); // No token, force login

  try {
    final response = await http.get(
        Uri.parse('${ApiHandler.baseUri}/Auth/ValidateToken'),
      //Uri.parse("https://paymanfintech.in/Auth/ValidateToken"),
      headers: {"Authorization": "Bearer $token"},
    );

    //print("🔵 Validate Token Response: ${response.statusCode}");
    //print("🔵 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["isValid"] == true; // Check if token is valid
    } else {
      prefs.remove("token"); // Clear invalid token
      return false;
    }
  } catch (e) {
    //print("🔴 Error validating token: $e");
    return false;
  }
}
