
// import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/home/cubit/map_cubit.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MapCubit(),
        ),
        //  BlocProvider(
        //   create: (_) => AuthenticationCubit(),
        // ),
      ],
      child: const _AppView(),
    );
    // return _AppView();
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
      
      // builder: (context, child) => ResponsiveBreakpoints.builder(
      //   child: MediaQuery(
      //       data: MediaQuery.of(context).copyWith(
      //         textScaler: const TextScaler.linear(1.0),
      //         boldText: false,
      //       ),
      //       child: child!,
      //     ),
      //   breakpoints: [
      //     const Breakpoint(start: 0, end: 480, name: MOBILE),
      //     const Breakpoint(start: 481, end: 800, name: TABLET),
      //     const Breakpoint(start: 801, end: 1920, name: DESKTOP),
      //     const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      //   ],
      // ),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
              boldText: false,
            ),
            child: child!,
          ),
      home: Container(
        color: Colors.white,
        child: SafeArea(
          //  top: false,
            // bottom: false,
            // maintainBottomViewPadding: true,
            minimum: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom
            ),
          child: HomeView())),
    );
  }
}

