
// import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:ommo/home/home.dart';
import 'package:responsive_framework/responsive_framework.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:general_repository/general_repository.dart';

import '../../utils/utils.dart';
// import '../app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({
    super.key,
    // required this.authenticationRepository,
    // required this.generalRepository,
  });

  // final AuthenticationRepository authenticationRepository;
  // final GeneralRepository generalRepository;

  @override
  Widget build(BuildContext context) {
    // return MultiRepositoryProvider(
    //   providers: [
    //     // RepositoryProvider.value(value: authenticationRepository),
    //     RepositoryProvider.value(value: generalRepository),
    //   ],
    //   child: MultiBlocProvider(
    //     providers: [
    //       // BlocProvider(
    //       //   create: (_) => AppCubit(authenticationRepository)..initializeApp(),
    //       // ),
    //       //  BlocProvider(
    //       //   create: (_) => AuthenticationCubit(),
    //       // ),
    //     ],
    //     child: const _AppView(),
    //   ),
    // );
    return _AppView();
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OMMO",
      navigatorKey: navigatorKey,
      theme: AppTheme().themeData,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
              boldText: false,
            ),
            child: child!,
          ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      // builder:
          // (context, child) => MediaQuery(
          //   data: MediaQuery.of(context).copyWith(
          //     textScaler: const TextScaler.linear(1.0),
          //     boldText: false,
          //   ),
          //   child: child!,
          // ),
      home: HomeView(),
    );
  }
}

