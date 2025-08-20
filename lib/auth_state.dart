import 'package:equatable/equatable.dart';
import 'model/user_model.dart';

/// Abstract base class for authentication states, extending Equatable for value-based equality.
/// This class provides a foundation for all authentication-related states and ensures
/// proper equality comparison using the [props] getter.
abstract class AuthState extends Equatable {
  /// Returns a list of properties that define the equality of this state.
  /// Subclasses should override this to include their specific properties.
  @override
  List<Object?> get props => [];
}

/// State representing the initial state before any authentication check or action is performed.
/// This is the default state when the [AuthCubit] is instantiated.
class AuthInitial extends AuthState {}

/// State representing an unauthenticated user.
/// This state is emitted when no valid authentication session exists.
class Unauthenticated extends AuthState {}

/// State representing an ongoing authentication process (e.g., login, signup, or token refresh).
/// This state indicates that an asynchronous authentication operation is in progress.
class AuthLoading extends AuthState {}

/// State representing a successfully authenticated user.
/// This state is emitted when a user is successfully logged in, signed up, or authenticated.
class Authenticated extends AuthState {
  /// The authenticated user containing details like ID, email, role, and name.
  final AppUser user;

  /// The authentication token used for authorized API requests.
  final String token;

  /// Creates an [Authenticated] state with the given [user] and [token].
  /// Both parameters are required and should be non-null.
  Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token]; // Includes user and token for equality
}

/// State representing an authentication error.
/// This state is emitted when an authentication operation (e.g., login, signup) fails.
class AuthError extends AuthState {
  /// The error message describing the reason for the authentication failure.
  final String message;

  /// Creates an [AuthError] state with the given [message].
  /// The [message] should be non-null and provide context for the error.
  AuthError({required this.message});

  @override
  List<Object?> get props => [message]; // Includes message for equality
}