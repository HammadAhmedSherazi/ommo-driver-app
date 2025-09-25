import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/utils/utils.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> with WidgetsBindingObserver {
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    handleLowMemory();
  }

  handleLowMemory() async {
    print("System is running extremely low on memory!");
    print("Clearing HERE SDK's internal memory caches.");
    SDKNativeEngine.sharedInstance!.purgeMemoryCaches(
      SDKNativeEnginePurgeMemoryStrategy.full,
    );
    AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret(
      AppKeys().accessKeyId,
      AppKeys().accessKeySecret,
    );
    SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(
      authenticationMode,
    );
    sdkOptions.lowMemoryMode = true;

    try {
      await SDKNativeEngine.makeSharedInstance(sdkOptions);
      print("Low Memory: Low memory mode has been enabled.");
    } on InstantiationException catch (e) {
      print("Low Memory: Failed to enable low memory mode: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        context.read<TruckNavigationCubit>().startListeningToLocation();
      }
    });
    _appLifecycleListener = AppLifecycleListener(
      onDetach: () => {_disposeHERESDK()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (previous, current) =>
          previous.isMapLoading != current.isMapLoading ||
          previous.mapController != current.mapController,
      builder: (context, state) {
        return state.isMapLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColorTheme().primary,
                ),
              )
            : SizedBox(
                height: context.screenHeight * 0.7,
                width: context.screenWidth,
                child: HereMap(
                  onMapCreated: context
                      .read<TruckNavigationCubit>()
                      .onMapCreated,
                ),
              );
      },
    );
  }

  @override
  void dispose() {
    _disposeHERESDK();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _disposeHERESDK() async {
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    _appLifecycleListener.dispose();
  }
}
