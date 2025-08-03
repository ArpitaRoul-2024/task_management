import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser extends Equatable {
  final String id; // Matches Supabase users.id (UUID from Google or backend)
  final String email;
  final String role; // Can be fetched from backend or defaulted
  final String? name; // Optional, from Google profile
  final String? token; // JWT token for Supabase authentication

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'User',
      name: json['name'] as String?,
      token: json['token'] as String?, // Include token from backend response
    );
  }

  factory AppUser.fromGoogleSignIn(GoogleSignInAccount account, {String? token}) {
    return AppUser(
      id: account.id,
      email: account.email,
      role: 'User', // Default role, update via backend
      name: account.displayName,
      token: token, // Token from Google Sign-In or Supabase exchange
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'token': token,
    };
  }

  @override
  List<Object?> get props => [id, email, role, name, token];
}