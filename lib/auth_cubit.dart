import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repo.dart';
import 'auth_state.dart';
import 'model/user_model.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  String? _token;
  AppUser? _currentUser;

  AuthCubit(this.authRepo) : super(AuthInitial()) {
    _loadSavedAuth();
  }

  String? get token => _token;
  AppUser? get currentUser => _currentUser;

  // Load saved token and check auth state on initialization
  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null) {
      _token = savedToken;
      await checkAuth();
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
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
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
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      emit(Authenticated(user: _currentUser!, token: _token!));
    } catch (e) {
      emit(AuthError(message: 'Signup failed: $e'));
    }
  }

  Future<void> checkAuth() async {
    emit(AuthLoading());
    print('Checking auth state...');
    try {
      final result = await authRepo.checkAuth();
      if (result != null) {
        _token = result['token'];
        _currentUser = result['user'];
        // Save or update token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        print('Auth successful, emitting Authenticated: $_currentUser');
        emit(Authenticated(user: _currentUser!, token: _token!));
      } else {
        print('No valid auth, emitting Unauthenticated');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('Auth error: $e, emitting AuthError');
      emit(AuthError(message: 'Error checking authentication: $e'));
    }
  }

  Future<void> signOut() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    emit(Unauthenticated());
  }

  // Helper to ensure token is refreshed if needed
  Future<void> refreshToken() async {
    if (_token != null) {
      try {
        final result = await authRepo.refreshToken(_token!);
        if (result != null) {
          _token = result['token'];
          _currentUser = result['user']; // Update user if provided, can be null
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          emit(Authenticated(user: _currentUser ?? _currentUser!, token: _token!)); // Fallback to existing user if null
        }
      } catch (e) {
        print('Token refresh failed: $e');
        await signOut();
      }
    }
  }}