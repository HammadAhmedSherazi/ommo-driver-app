import 'package:equatable/equatable.dart';

import '../models/user_model.dart';

enum ProfileStatus { initial, loading, loaded, updating, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.user,
    this.status = ProfileStatus.initial,
    this.errorMessage,
  });

  final UserModel? user;
  final ProfileStatus status;
  final String? errorMessage;

  ProfileState copyWith({
    UserModel? user,
    ProfileStatus? status,
    String? errorMessage,
  }) {
    return ProfileState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [user, status, errorMessage];
}
