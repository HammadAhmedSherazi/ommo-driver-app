import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/services/predictive_back_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/home/cubit/map_state.dart';
import 'package:ommo/utils/utils.dart';

import '../../map_sdk/truck_guidance_example.dart';
import '../cubit/map_cubit.dart';

class MapView extends StatefulWidget {
  final HereMapController? controller;
  // final void Function(HereMapController)? onMapCreated;
  const MapView({super.key,  this.controller});

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

class MapViewState extends State<MapView> implements UICallback,WidgetsBindingObserver {
  // String _truckSpeedLimit = "";
  // String _carSpeedLimit = "";
  // String _drivingSpeed = "";
  // String _truckRestrictionDescription = "";
  TruckGuidanceExample? _truckGuidanceExample;
  HereMapController? _hereMapController;
  late final AppLifecycleListener _appLifecycleListener;
  bool showStartLocationSuggestionModal = false;
  bool showEndLocationSuggestionModal = false;
  bool isLoad = false;
  bool startingNavigating = false;
  List<Suggestion> suggestions = [];
  final TextEditingController currentLocationTextfield = TextEditingController(
    text: "New York Logistics, 2856 E 195th St, Bronx, NY 10461, United States",
  );
  final TextEditingController destinationLocationTextfield =
      TextEditingController();
  GeoCoordinates? startLocation = TruckGuidanceExample.myStartCoordinadtes;
  GeoCoordinates? destinationLocation;
handleLowMemory() async {
  print("System is running extremely low on memory!");
  print("Clearing HERE SDK's internal memory caches.");

  SDKNativeEngine.sharedInstance!.purgeMemoryCaches(SDKNativeEnginePurgeMemoryStrategy.full);

  AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret("YOUR_ACCESS_KEY_ID", "YOUR_ACCESS_KEY_SECRET");
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
    return BlocBuilder<MapCubit, MapState>(
      // buildWhen: (previous, current) => previous.mapController != current.mapController,
      builder: (context, state) {
        return SizedBox(
          height: context.screenHeight * 0.7,
          width: context.screenWidth,
          child: HereMap(onMapCreated: context.read<MapCubit>().onMapCreated));
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
    Future.delayed(Duration(seconds: 4),(){
      if(mounted){
      context.read<MapCubit>().initialMap(this);

      }
    });
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleListener = AppLifecycleListener(
      onDetach: () => {
        // print('AppLifecycleListener detached.')
        // ,
        _disposeHERESDK(),
      },
    );
  }

  @override
  void dispose() {
    _disposeHERESDK();
    
    super.dispose();
  }

  void _disposeHERESDK() async {
    // Free HERE SDK resources before the application shuts down.
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    WidgetsBinding.instance.removeObserver(this);
    
    _appLifecycleListener.dispose();
  }

  // A helper method to add a button on top of the HERE map.
  Align button(String buttonLabel, Function callbackFunction) {
    return Align(
      alignment: Alignment.topCenter,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.lightBlueAccent,
        ),
        onPressed: () => callbackFunction(),
        child: Text(buttonLabel, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  // A helper method to show a dialog.
  Future<void> _showDialog(String title, String message) async {
    // return showDialog<void>(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text(title),
    //       content: SingleChildScrollView(
    //         child: ListBody(
    //           children: <Widget>[
    //             Text(message),
    //           ],
    //         ),
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           child: const Text('OK'),
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

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
