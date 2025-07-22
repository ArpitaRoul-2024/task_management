import 'package:flutter_bloc/flutter_bloc.dart';
  import 'auth_repo.dart';
import 'auth_state.dart';
import 'model/user_model.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  String? _token;
  AppUser? _currentUser;

  AuthCubit(this.authRepo) : super(Unauthenticated());

  String? get token => _token;
  AppUser? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final result = await authRepo.login(email, password);
      _token = result['token'];
      _currentUser = result['user'];
      emit(Authenticated(user: _currentUser!, token: _token!));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final result = await authRepo.signUp(
        name: name,
        email: email,
        password: password,
      );
      _token = result['token'];
      _currentUser = result['user'];
      emit(Authenticated(user: _currentUser!, token: _token!));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> checkAuth() async {
    emit(AuthLoading());
    // Placeholder for checking persistent token (e.g., using shared_preferences)
    emit(Unauthenticated());
  }

  void signOut() {
    _token = null;
    _currentUser = null;
    emit(Unauthenticated());
  }
}