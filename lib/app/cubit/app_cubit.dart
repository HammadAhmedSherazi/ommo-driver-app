// import 'dart:async';

// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:cache/cache.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../utils/utils.dart';

// part 'app_state.dart';

// class AppCubit extends Cubit<AppState> {
//   AppCubit(this.authenticationRepository, {CacheClient? cache})
//     : cache = cache ?? CacheClient(),
//       super(
//         authenticationRepository.currentUser.isNotEmpty
//             ? AppState.authenticated(authenticationRepository.currentUser, true)
//             : const AppState.unauthenticated(true),
//       ) {
//     userSubscription = authenticationRepository.user.listen(
//       (user) => changeAppState(user),
//     );
//   }

//   final AuthenticationRepository authenticationRepository;
//   late final StreamSubscription<UserAuthentication> userSubscription;
//   final CacheClient cache;

//   void changeAppState(UserAuthentication user) {
//     emit(
//       user.isNotEmpty
//           ? AppState.authenticated(user, state.showOnboarding)
//           : AppState.unauthenticated(state.showOnboarding),
//     );
//   }

//   void initializeApp() {
//     // fcmService.initializeFcmService();

//     final showOnboarding = cache.read<bool>(key: AppKeys.onboardingCacheKey);

//     emit(state.copyWith(showOnboarding: showOnboarding ?? true));
//   }

//   void disableOnboarding() {
//     emit(state.copyWith(showOnboarding: false));
//     cache.write<bool>(key: AppKeys.onboardingCacheKey, value: false);
//   }

//   void logout() {
//    authenticationRepository.logout();
//   }

//   @override
//   Future<void> close() {
//     userSubscription.cancel();
//     authenticationRepository.dispose();
//     return super.close();
//   }
// }
