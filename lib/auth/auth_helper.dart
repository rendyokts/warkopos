import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:warkopos/const/base_url.dart';

class AuthHelper {
  // Fungsi untuk cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // Fungsi untuk mendapatkan token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Fungsi untuk mendapatkan data user
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'username': prefs.getString('user_username'),
    };
  }

  // Fungsi untuk logout
  static Future<bool> logout() async {
    try {
      final token = await getToken();

      if (token != null) {
        // Panggil API logout jika ada
        await http.post(
          Uri.parse('${BaseUrl.baseUrl}/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Hapus data local
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return true;
    } catch (e) {
      print('Logout error: $e');
      // Tetap hapus data local meskipun API gagal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return false;
    }
  }

  // Fungsi untuk mendapatkan headers dengan authorization
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fungsi untuk validasi token (opsional)
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse(
          '${BaseUrl.baseUrl}/user',
        ), // Endpoint untuk mendapatkan data user
        headers: await getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }
}
