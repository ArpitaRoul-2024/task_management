import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/user_model.dart';

class AuthRepo {
  final String baseUrl = 'https://task-management-9gaz.onrender.com/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Login successful, token saved: $token');
      return {
        'token': token,
        'user': user,
      };
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to login';
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Signup successful, token saved: $token');
      return {
        'token': token,
        'user': user,
      };
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to sign up';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>?> checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      print('Checking auth, stored token: $storedToken');
      if (storedToken != null) {
        final response = await http.get(
          Uri.parse('$baseUrl/check-auth'),
          headers: {'Authorization': 'Bearer $storedToken'},
        );
        print('Check-auth response status: ${response.statusCode}, body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
          return {
            'token': data['token'],
            'user': user,
          };
        } else {
          print('Invalid token, clearing auth_token');
          await prefs.remove('auth_token');
          return null;
        }
      }
      print('No stored token found');
      return null;
    } catch (e) {
      print('Error checking auth: $e');
      return null;
    }
  }}