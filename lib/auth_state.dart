import 'package:equatable/equatable.dart';

import 'model/user_model.dart';

/// Abstract base class for authentication states, extending Equatable for value-based equality.
abstract class AuthState extends Equatable {
  /// Returns a list of properties that define the equality of this state.
  @override
  List<Object?> get props => [];
}

/// State representing an unauthenticated user.
class Unauthenticated extends AuthState {}

/// State representing an ongoing authentication process.
class AuthLoading extends AuthState {}

/// State representing a successfully authenticated user.
class Authenticated extends AuthState {
  /// The authenticated user.
  final AppUser user;

  /// The authentication token.
  final String token;

  /// Creates an Authenticated state with the given user and token.
  Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token]; // Includes all relevant properties for equality
}

/// State representing an authentication error.
class AuthError extends AuthState {
  /// The error message describing the authentication failure.
  final String message;

  /// Creates an AuthError state with the given message.
  AuthError({required this.message});

  @override
  List<Object?> get props => [message]; // Includes the message for equality
}