import 'package:equatable/equatable.dart';

import 'model/user_model.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  final String token;

  Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}