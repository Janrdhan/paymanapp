import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:paymanapp/screens/Services/session_manager.dart';
import 'package:paymanapp/widgets/api_handler.dart';
class ApiClient {

  static Future<http.Response> get(String url) async {
    var token = await SessionManager.getToken();

    if (token != null && JwtDecoder.isExpired(token)) {
      token = await _refreshToken();
    }

    return http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<String?> _refreshToken() async {
    final refresh = await SessionManager.getRefreshToken();

    final res = await http.post(
      Uri.parse('${ApiHandler.baseUri1}/Users/RefreshToken'),
      body: {"refreshToken": refresh},
    );

    if (res.statusCode == 200) {
      final newToken = res.body;
      // await SessionManager.saveSession(
      //   token: newToken,
      //   refreshToken: refresh!,
      //   phone: "",
      // );
      return newToken;
    }

    //await SessionManager.clear();
    return null;
  }
}
