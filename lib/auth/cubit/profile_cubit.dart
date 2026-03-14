import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/user_model.dart';
import '../service/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profileService) : super(const ProfileState());

  final ProfileService _profileService;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, errorMessage: null));
    final result = await _profileService.getProfile();
        log(result.toString());

    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        user: result.data,
        status: ProfileStatus.loaded,
      ));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: result.errorMessage ?? 'Failed to load profile',
      ));
    }
  }

  Future<void> updateProfile(UserModel user) async {
    emit(state.copyWith(status: ProfileStatus.updating, errorMessage: null));
    final result = await _profileService.updateProfile(user);
    log(result.toString());
    if (result.isSuccess && result.data != null) {
      loadProfile();
      emit(state.copyWith(
        user: result.data,
        status: ProfileStatus.loaded,
      ));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: result.errorMessage ?? 'Failed to update profile',
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
