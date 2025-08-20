import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepo {
  final String baseUrl = 'https://task-management-9gaz.onrender.com/api';

  bool _isValidJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      for (final part in parts) {
        base64Url.normalize(part);
        base64Decode(part);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;

      if (!_isValidJwt(token)) {
        throw Exception('Invalid JWT');
      }

      final user = AppUser.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name ?? '');

      return {'token': token, 'user': user};
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;

      if (!_isValidJwt(token)) {
        throw Exception('Invalid JWT');
      }

      final user = AppUser.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.name ?? '');

      return {'token': token, 'user': user};
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Signup failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>?> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final email = prefs.getString('user_email');
    final name = prefs.getString('user_name');

    if (storedToken != null && email != null && name != null) {
      if (_isValidJwt(storedToken)) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(storedToken.split('.')[1]))));
        final user = AppUser(
          id: payload['sub'],
          email: email,
          name: name,
          role: payload['role'] ?? 'User',
          token: storedToken,
        );
        return {'token': storedToken, 'user': user};
      } else {
        await prefs.remove('auth_token');
        return null;
      }
    }
    return null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
  }
}
