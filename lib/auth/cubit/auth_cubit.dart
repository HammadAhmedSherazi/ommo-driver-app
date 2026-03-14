import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(const AuthState());

  final AuthService _authService;

  Future<void> checkAuth() async {
    emit(state.copyWith(status: AuthStatus.initial, errorMessage: null));
    final bool isLoggedIn = await _authService.isLoggedIn();
    emit(state.copyWith(
      status: isLoggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    ));
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(errorMessage: null, status: AuthStatus.loading));
    final result = await _authService.login(email: email, password: password);
    if (result.success) {
      emit(state.copyWith(status: AuthStatus.authenticated));
    } else {
      emit(state.copyWith(
          errorMessage: result.errorMessage,
          status: AuthStatus.unauthenticated));
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String employmentType,
    required String cdlLicenseNumber,
    required String licenseState,
  }) async {
    emit(state.copyWith(errorMessage: null, status: AuthStatus.loading));
    final result = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phone: phone,
      employmentType: employmentType,
      cdlLicenseNumber: cdlLicenseNumber,
      licenseState: licenseState,
    );
    if (result.success) {
      emit(state.copyWith(status: AuthStatus.authenticated));
    } else {
      emit(state.copyWith(
          errorMessage: result.errorMessage,
          status: AuthStatus.unauthenticated));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
