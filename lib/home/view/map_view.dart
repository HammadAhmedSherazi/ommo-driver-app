import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/utils/utils.dart';

class MapView extends StatefulWidget {
  final double? height;
  const MapView({super.key, this.height});

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  // late final AppLifecycleListener _appLifecycleListener;

  // @override
  // void didHaveMemoryPressure() {
  //   super.didHaveMemoryPressure();
  //   handleLowMemory();
  // }

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
    // WidgetsBinding.instance.addObserver(this);
    // Location is started from TruckNavigationCubit.onMapCreated so the HERE
    // LocationEngine starts as soon as the map is ready (no delay = faster first fix).
  }
  // _appLifecycleListener = AppLifecycleListener(
  //   onDetach: () {
  //     log("_map on Detach Called");
  //     _disposeHERESDK();
  //   },
  // );

  @override
  Widget build(BuildContext context) {
    // Platform views (HereMap) often flash black when their size changes. With
    // resizeToAvoidBottomInset, the keyboard shrinks MediaQuery.size — treat
    // layout height as full window using viewInsets so the map size stays stable.
    // final mq = MediaQuery.of(context);
    // final fullHeight = mq.size.height + mq.viewInsets.bottom;
    // final fullWidth = mq.size.width;
    // final h = widget.height ?? fullHeight * 0.75;

    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (previous, current) =>
          previous.mapController != current.mapController,
      builder: (context, state) {
        return SizedBox(
          height: widget.height ?? double.infinity,
          width: double.infinity,
          child: HereMap(
            onMapCreated: context.read<TruckNavigationCubit>().onMapCreated,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Do not call SDKNativeEngine.dispose / SdkContext.release here. The engine
    // is created once in main(); disposing it when this widget is removed
    // destroys the map for the whole app and causes black tiles if another
    // HereMap mounts (e.g. navigation UI swap, routes). Teardown belongs at app
    // exit only.
    super.dispose();
  }
}
