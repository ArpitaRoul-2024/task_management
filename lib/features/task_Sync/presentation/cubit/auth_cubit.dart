import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositaries/auth_repo.dart';
import 'auth_state.dart';
import '../../data/models/user_model.dart';
import '../pages/activity.dart'; // Import activity.dart for Activity widget and ActivityManager

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  String? _token;
  AppUser? _currentUser;

  AuthCubit(this.authRepo) : super(AuthInitial()) {
    _loadSavedAuth();
  }

  String? get token => _token;
  AppUser? get currentUser => _currentUser;

  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');

    if (savedToken != null && userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      _token = savedToken;
      _currentUser = AppUser.fromJson(userMap);
      emit(Authenticated(user: _currentUser!, token: _token!));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final result = await authRepo.login(email, password);
      _token = result['token'];
      _currentUser = result['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      // Log the login activity using ActivityManager
      await ActivityManager.logActivity('User logged in: ${_currentUser!.email}');

      emit(Authenticated(user: _currentUser!, token: _token!));
    } catch (e) {
      emit(AuthError(message: 'Login failed: $e'));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final result = await authRepo.signUp(name: name, email: email, password: password);
      _token = result['token'];
      _currentUser = result['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      // Log the signup activity using ActivityManager
      await ActivityManager.logActivity('User signed up: ${_currentUser!.email}');

      emit(Authenticated(user: _currentUser!, token: _token!));
    } catch (e) {
      emit(AuthError(message: 'Signup failed: $e'));
    }
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');

    if (savedToken != null && userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      _token = savedToken;
      _currentUser = AppUser.fromJson(userMap);
      emit(Authenticated(user: _currentUser!, token: _token!));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    // Log the logout activity using ActivityManager
    await ActivityManager.logActivity('User logged out');

    emit(Unauthenticated());
  }
}