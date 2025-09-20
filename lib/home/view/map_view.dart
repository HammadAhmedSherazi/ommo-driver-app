import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/home/cubit/map_state.dart';
import 'package:ommo/home/view/truck_navigation/cubit/truck_navigation_cubit.dart';
import 'package:ommo/home/view/truck_navigation/cubit/truck_navigation_state.dart';
import 'package:ommo/utils/utils.dart';

class MapView extends StatefulWidget {
  final HereMapController? controller;
  // final void Function(HereMapController)? onMapCreated;
  const MapView({super.key, this.controller});

  @override
  MapViewState createState() => MapViewState();
}

abstract class UICallback {
  void onTruckSpeedLimit(String speedLimit);
  void onCarSpeedLimit(String speedLimit);
  void onDrivingSpeed(String drivingSpeed);
  void onTruckRestrictionWarning(String description);
  void onHideTruckRestrictionWarning();
}

class MapViewState extends State<MapView> implements UICallback, WidgetsBindingObserver {
  late final AppLifecycleListener _appLifecycleListener;
  bool showStartLocationSuggestionModal = false;
  bool showEndLocationSuggestionModal = false;
  bool isLoad = false;
  bool startingNavigating = false;

  handleLowMemory() async {
    print("System is running extremely low on memory!");
    print("Clearing HERE SDK's internal memory caches.");
    SDKNativeEngine.sharedInstance!.purgeMemoryCaches(SDKNativeEnginePurgeMemoryStrategy.full);
    AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret(AppKeys().accessKeyId, AppKeys().accessKeySecret);
    SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);
    sdkOptions.lowMemoryMode = true;

    try {
      await SDKNativeEngine.makeSharedInstance(sdkOptions);
      print("Low Memory: Low memory mode has been enabled.");
    } on InstantiationException catch (e) {
      print("Low Memory: Failed to enable low memory mode: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      // buildWhen: (previous, current) => previous.mapController != current.mapController,
      builder: (context, state) {
        return SizedBox(
          height: context.screenHeight * 0.7,
          width: context.screenWidth,
          child: HereMap(onMapCreated: context.read<TruckNavigationCubit>().onMapCreated),
        );
      },
    );
  }

  // UICallback implementations.
  @override
  void onCarSpeedLimit(String speedLimit) {
    // setState(() {
    // _carSpeedLimit = speedLimit;
    // });
  }

  @override
  void onDrivingSpeed(String drivingSpeed) {
    // setState(() {
    // _drivingSpeed = drivingSpeed;
    // });
  }

  @override
  void onTruckRestrictionWarning(String description) {
    // setState(() {
    // _truckRestrictionDescription = description;
    // });
  }

  @override
  void onTruckSpeedLimit(String speedLimit) {
    // setState(() {
    // _truckSpeedLimit = speedLimit;
    // });
  }

  @override
  void onHideTruckRestrictionWarning() {
    // setState(() {
    // _truckRestrictionDescription = "";
    // });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        // context.read<MapCubit>().initialMap(this);
        context.read<TruckNavigationCubit>().startListeningToLocation();
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleListener = AppLifecycleListener(onDetach: () => {_disposeHERESDK()});
  }

  @override
  void dispose() {
    _disposeHERESDK();
    super.dispose();
  }

  void _disposeHERESDK() async {
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    WidgetsBinding.instance.removeObserver(this);
    _appLifecycleListener.dispose();
  }

  // Align button(String buttonLabel, Function callbackFunction) {
  //   return Align(
  //     alignment: Alignment.topCenter,
  //     child: ElevatedButton(
  //       style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.lightBlueAccent),
  //       onPressed: () => callbackFunction(),
  //       child: Text(buttonLabel, style: const TextStyle(fontSize: 20)),
  //     ),
  //   );
  // }

  @override
  void didChangeAccessibilityFeatures() {
    // TODO: implement didChangeAccessibilityFeatures
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // TODO: implement didChangeLocales
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
  }

  @override
  void didChangePlatformBrightness() {
    // TODO: implement didChangePlatformBrightness
  }

  @override
  void didChangeTextScaleFactor() {
    // TODO: implement didChangeTextScaleFactor
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    // TODO: implement didChangeViewFocus
  }

  @override
  void didHaveMemoryPressure() {
    handleLowMemory();
  }

  @override
  Future<bool> didPopRoute() {
    // TODO: implement didPopRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRoute(String route) {
    // TODO: implement didPushRoute
    throw UnimplementedError();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    // TODO: implement didPushRouteInformation
    throw UnimplementedError();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    // TODO: implement didRequestAppExit
    throw UnimplementedError();
  }

  @override
  void handleCancelBackGesture() {
    // TODO: implement handleCancelBackGesture
  }

  @override
  void handleCommitBackGesture() {
    // TODO: implement handleCommitBackGesture
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // TODO: implement handleStartBackGesture
    throw UnimplementedError();
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    // TODO: implement handleUpdateBackGestureProgress
  }
}
