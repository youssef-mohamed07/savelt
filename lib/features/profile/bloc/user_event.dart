import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UpdateUserName extends UserEvent {
  final String name;

  const UpdateUserName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateUserEmail extends UserEvent {
  final String email;

  const UpdateUserEmail(this.email);

  @override
  List<Object?> get props => [email];
}

class UpdateUserProfile extends UserEvent {
  final String name;
  final String? email;

  const UpdateUserProfile({required this.name, this.email});

  @override
  List<Object?> get props => [name, email];
}

// TODO: Add LoadUserFromFirebase event when Firebase is connected
class LoadUserFromFirebase extends UserEvent {}
