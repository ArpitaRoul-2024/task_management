import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/user_model.dart';

class AuthRepo {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String baseUrl = 'https://task-management-9gaz.onrender.com/api';

  bool _isValidJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT: Incorrect number of parts (${parts.length})');
        return false;
      }
      print('JWT Header: ${parts[0]}');
      print('JWT Payload: ${parts[1]}');
      print('JWT Signature: ${parts[2]}');
      for (final part in parts) {
        base64Decode(part); // Will throw if invalid base64
      }
      print('JWT validated successfully: $token');
      return true;
    } catch (e) {
      print('Invalid JWT format: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      if (!_isValidJwt(token)) {
        throw Exception('Received invalid JWT from server: $token');
      }
      final userData = data['user'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Login successful, token saved: $token');

      try {
        await _supabase.auth.setSession(token);
      } catch (e) {
        print('Failed to set Supabase session: $e');
        await prefs.remove('auth_token');
        throw Exception('Invalid token for Supabase: $e');
      }

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
    print('Signup response body: ${response.body}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      if (!_isValidJwt(token)) {
        throw Exception('Received invalid JWT from server: $token');
      }
      final userData = data['user'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Signup successful, token saved: $token');

      try {
        await _supabase.auth.setSession(token);
      } catch (e) {
        print('Failed to set Supabase session: $e');
        await prefs.remove('auth_token');
        throw Exception('Invalid token for Supabase: $e');
      }

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
        final response = await _supabase.auth.getUser(storedToken);
        if (response.user != null) {
          final user = AppUser.fromJson({
            'id': response.user!.id,
            'email': response.user!.email ?? '',
            'role': 'User',
            'name': response.user!.userMetadata?['name'],
          });
          print('Check-auth response status: 200, user: $user');
          return {'token': storedToken, 'user': user};
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
  }

  Future<Map<String, dynamic>?> refreshToken(String currentToken) async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        final newToken = response.session!.accessToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', newToken);
        print('Token refreshed successfully: $newToken');

        final userResponse = await _supabase.auth.getUser(newToken);
        final user = userResponse.user != null
            ? AppUser.fromJson({
          'id': userResponse.user!.id,
          'email': userResponse.user!.email ?? '',
          'role': 'User',
          'name': userResponse.user!.userMetadata?['name'],
        })
            : null;

        return {
          'token': newToken,
          'user': user,
        };
      }
      return null;
    } catch (e) {
      print('Token refresh failed: $e');
      return null;
    }
  }
}