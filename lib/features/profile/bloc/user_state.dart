import 'package:equatable/equatable.dart';

class UserState extends Equatable {
  final String name;
  final String? email;

  const UserState({
    this.name = '',
    this.email,
  });

  UserState copyWith({
    String? name,
    String? email,
  }) {
    return UserState(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  // Get first name only (for Home page greeting)
  String get firstName => name.split(' ').first;

  // Get initials for avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  List<Object?> get props => [name, email];
}
