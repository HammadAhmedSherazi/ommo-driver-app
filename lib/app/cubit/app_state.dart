// part of 'app_cubit.dart';

// enum AppStatus { authenticated, unauthenticated }

// class AppState extends Equatable {
//   const AppState._({
//     required this.status,
//     this.user = UserAuthentication.empty,
//     this.showOnboarding = true,
//   });

//   const AppState.authenticated(UserAuthentication user, bool showOnboarding)
//     : this._(
//         status: AppStatus.authenticated,
//         user: user,
//         showOnboarding: showOnboarding,
//       );

//   const AppState.unauthenticated(bool showOnboarding)
//     : this._(status: AppStatus.unauthenticated, showOnboarding: showOnboarding);

//   bool get isAuthenticated => status == AppStatus.authenticated;

//   final AppStatus status;
//   final UserAuthentication user;
//   final bool showOnboarding;

//   AppState copyWith({
//     AppStatus? status,
//     UserAuthentication? user,
//     bool? showOnboarding,
//   }) => AppState._(
//     status: status ?? this.status,
//     user: user ?? this.user,
//     showOnboarding: showOnboarding ?? this.showOnboarding,
//   );

//   @override
//   List<Object?> get props => [status, user, showOnboarding];
// }
