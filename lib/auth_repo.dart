import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final data = jsonDecode(response.body);
      print( "Status received");
      return {
        'token': data['token'],
        'user': AppUser.fromJson(data['user']),
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
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'user': AppUser.fromJson(data['user']),
      };
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to sign up';
      throw Exception(error);
    }
  }
}