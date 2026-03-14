// import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/auth/auth.dart';
import 'package:ommo/home/home.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stop_cubit.dart';
import 'package:ommo/logic/trucking_main_state/trucking_main_state_cubit.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
import 'package:ommo/services/hive/recent_search/service/recent_search_services.dart';
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
        BlocProvider(create: (_) => AuthCubit(AuthService())),
        BlocProvider(create: (_) => ProfileCubit(ProfileService())),
        BlocProvider(create: (_) => TruckingStateCubit(TruckingState.initial)),
        BlocProvider(create: (_) => TruckSpecificationsCubit()),
        BlocProvider(create: (_) => TruckNavigationCubit()),
        BlocProvider(create: (_) => TruckStopCubit()),
        BlocProvider(create: (_) => RecentSearchCubit(RecentSearchService())),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0), boldText: false),
        child: child!,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Container(
              color: Colors.white,
              child: SafeArea(
                minimum: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: const SplashScreen(),
              ),
            ),
        '/login': (context) => Container(
              color: Colors.white,
              child: SafeArea(
                minimum: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: const LoginScreen(),
              ),
            ),
        '/home': (context) => Container(
              color: Colors.white,
              child: SafeArea(
                minimum: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: HomeView(),
              ),
            ),
      },
    );
  }
}
