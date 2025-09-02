import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';

import '../../map_sdk/truck_guidance_example.dart';

class MapView extends StatefulWidget {
  final void Function(HereMapController)? onMapCreated;
  const MapView({super.key, required this.onMapCreated});

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

class MapViewState extends State<MapView> implements UICallback {
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
  final TextEditingController currentLocationTextfield =
      TextEditingController(
        text: "New York Logistics, 2856 E 195th St, Bronx, NY 10461, United States"
      );
  final TextEditingController destinationLocationTextfield =
      TextEditingController();
  GeoCoordinates? startLocation = TruckGuidanceExample.myStartCoordinadtes;
  GeoCoordinates? destinationLocation;


  @override
  Widget build(BuildContext context) {
    return  HereMap(
            onMapCreated: widget.onMapCreated,   
           
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
    _appLifecycleListener = AppLifecycleListener(
      onDetach: () =>
          {
            // print('AppLifecycleListener detached.')
            // ,
             _disposeHERESDK()
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

}
