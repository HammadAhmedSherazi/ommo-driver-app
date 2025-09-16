// map_cubit.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

import 'package:ommo/home/view/map_view.dart';
import '../../map_sdk/truck_guidance_example.dart';
import '../../utils/utils.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
 TruckGuidanceExample? _truckExampleInstance;
  MapCubit()
    : // initialize here
      super(MapState());

  void onMapCreated(HereMapController hereMapController) {
    _truckExampleInstance ??= TruckGuidanceExample((text1,text2)=>{}, hereMapController);
    // emit a new state with the controller set
    emit(state.copyWith(mapController: hereMapController));

    // Load the map scene after controller is set
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (
      error,
    ) {
      if (error != null) {
        print("Map scene not loaded. Error: ${error.toString()}");
        return;
      }
      // You can trigger further state updates here if needed
    });
  }

  void setMapViewScheme(MapScheme mapScheme){
     state.mapController?.mapScene.loadSceneForMapScheme(mapScheme, (
            MapError? error,
          ) {
            if (error != null) {
              print("Error loading scheme: $error");
            }
            // _enableSafetyCameras(_hereMapController!);
          });
      emit(state.copyWith(mapController: state.mapController));
  }

  void mapZoomIn(Point2D center){
     state.mapController?.camera.zoomBy(2.0, center);
      emit(state.copyWith(mapController: state.mapController));
  }
    void mapZoomOut(Point2D center){
     state.mapController?.camera.zoomBy(0.5, center);
      emit(state.copyWith(mapController: state.mapController));
  }

  void setCurrentLocationPoint( GeoCoordinates coords) {
    // Create marker (blue dot)
    _truckExampleInstance?.startGeoCoordinates = coords;
    MapImage userImage = MapImage.withFilePathAndWidthAndHeight(
      AppIcons.myLocIcon,
      40,
      40,
    ); // add your own icon
   
    state.mapController?.mapScene.addMapMarker( MapMarker(coords, userImage));

    // Create accuracy circle
    // GeoCircle geoCircle = GeoCircle(coords, accuracy); // accuracy in meters
    // GeoCircleStyle circleStyle = GeoCircleStyle()
    //   ..fillColor = Color.fromARGB(80, 0, 0, 255)  // semi-transparent blue
    //   ..strokeColor = Color.fromARGB(120, 0, 0, 200)
    //   ..strokeWidth = 2;

    // _accuracyCircle = MapPolygon(geoCircle., circleStyle);
    // controller.mapScene.addMapPolygon(_accuracyCircle);

    // Center camera
   state.mapController?.camera.lookAtPoint(coords);
   emit(state.copyWith(mapController: state.mapController, startCoordinates: state.startCoordinates));
  }
 searchLocation(String text,GeoCoordinates startLocCoordinate )  {

  _truckExampleInstance?.searchLocation(text).then((value){emit(state.copyWith(suggestionDestination: value));});
}


void setDestinationCoordinate(GeoCoordinates coordinate){
   _truckExampleInstance?.destinationGeoCoordinates = coordinate;
  emit(state.copyWith(
    destinationCoordinates: coordinate
  ));
}
 void setRoute(){
  _truckExampleInstance?.onShowRouteButtonClicked(state.startCoordinates ?? TruckGuidanceExample.myStartCoordinadtes, state.destinationCoordinates!);
  emit(state.copyWith(mapController: state.mapController));
 }

 void startNavigation(){
  _truckExampleInstance?.onStartStopButtonClicked();
  emit(state.copyWith(mapController: state.mapController));
 }



  void clearRoute() {
    _truckExampleInstance?.clearRoute();
    emit(state.copyWith(mapController: state.mapController));
  }

  void initialMap(UICallback callback) {
    _truckExampleInstance?.setUICallback(callback);
  }
}
