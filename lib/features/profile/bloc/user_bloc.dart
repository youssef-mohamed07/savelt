import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserState()) {
    on<UpdateUserName>(_onUpdateUserName);
    on<UpdateUserEmail>(_onUpdateUserEmail);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<LoadUserFromFirebase>(_onLoadUserFromFirebase);
  }

  void _onUpdateUserName(UpdateUserName event, Emitter<UserState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onUpdateUserEmail(UpdateUserEmail event, Emitter<UserState> emit) {
    emit(state.copyWith(email: event.email));
  }

  void _onUpdateUserProfile(UpdateUserProfile event, Emitter<UserState> emit) {
    emit(state.copyWith(
      name: event.name,
      email: event.email,
    ));
  }

  void _onLoadUserFromFirebase(LoadUserFromFirebase event, Emitter<UserState> emit) {
    // TODO: Implement Firebase Auth integration
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   emit(state.copyWith(
    //     name: user.displayName ?? 'User',
    //     email: user.email,
    //   ));
    // }
  }
}
