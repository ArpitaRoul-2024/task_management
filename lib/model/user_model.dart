import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String role;
  final String? name;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      role: json['role'] ?? 'User',
      name: json['name'],
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