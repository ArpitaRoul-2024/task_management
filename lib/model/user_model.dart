import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser extends Equatable {
  final String id; // Can be set to Google user ID
  final String email;
  final String role; // Can be defaulted or fetched from backend
  final String? name; // Optional, can be set from Google profile

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String, // Maps to Google user ID from backend response
      email: json['email'] as String, // Maps to Google email
      role: json['role'] as String? ?? 'User', // Default to 'User' if not provided
      name: json['name'] as String?, // Maps to Google display name if available
    );
  }

  factory AppUser.fromGoogleSignIn(GoogleSignInAccount account) {
    return AppUser(
      id: account.id, // Google user ID
      email: account.email, // Google email
      role: 'User', // Default role, can be updated by backend after token exchange
      name: account.displayName, // Google display name
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, email, role, name];
}