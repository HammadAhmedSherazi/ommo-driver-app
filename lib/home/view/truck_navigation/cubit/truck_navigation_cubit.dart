import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/animation.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/transport.dart';
import 'package:location/location.dart' as loc;
import 'package:ommo/home/view/truck_navigation/cubit/get_data.dart';
import 'package:ommo/home/view/truck_navigation/cubit/truck_navigation_state.dart';
import 'package:ommo/map_sdk/HEREPositioningSimulator.dart';
import 'package:ommo/map_sdk/truck_guidance_example.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/theme/theme.dart';

class TruckNavigationCubit extends Cubit<TruckNavigationState> {
  TruckNavigationCubit() : super(TruckNavigationState());

  final RoutingEngine _routingEngine = RoutingEngine();
  final SearchEngine _searchEngine = SearchEngine();

  VisualNavigator? _visualNavigator;
  Navigator? _navigator;

  LocationEngine? _locationEngine;
  HEREPositioningSimulator? _simulator;

  MapPolyline? _currentRoutePolyline;
  MapMarker? _currentLocationMarker;
  MapMarker? _startMarker;
  MapMarker? _destinationMarker;
  final loc.Location _location = loc.Location();

  void onMapCreated(HereMapController controller) {
    emit(state.copyWith(mapController: controller));

    // Load the map scene after controller is set
    controller.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (error) {
      if (error != null) {
        print("Map scene not loaded. Error: ${error.toString()}");
        return;
      }
      // You can trigger further state updates here if needed
    });
    _visualNavigator = VisualNavigator();
    _navigator = Navigator();
  }

  Future<GeoCoordinates?> _getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    loc.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return null;
    }

    loc.LocationData locationData = await _location.getLocation();
    return GeoCoordinates(locationData.latitude!, locationData.longitude!);
  }

  void startListeningToLocation() async {
    _locationEngine = LocationEngine();
    _locationEngine?.confirmHEREPrivacyNoticeInclusion();

    final GeoCoordinates? initialCoordinates = await _getCurrentLocation();

    if (initialCoordinates != null) {
      _updateCurrentLocationMarker(initialCoordinates);
    }

    _locationEngine?.addLocationListener(
      LocationListener((Location location) {
        final coords = location.coordinates;
        emit(state.copyWith(startCoordinates: coords));
        if (!state.isNavigating) {
          _updateCurrentLocationMarker(coords);
        }
        if (state.isNavigating) {
          _visualNavigator?.onLocationUpdated(location);
          _navigator?.onLocationUpdated(location);
        }
      }),
    );

    _locationEngine?.startWithLocationAccuracy(LocationAccuracy.bestAvailable);
  }

  void searchPlaces(String query) {
    if (state.startCoordinates == null) return;
    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 5;

    TextQueryArea queryArea = TextQueryArea.withCenter(state.startCoordinates!);

    _searchEngine.suggestByText(TextQuery.withArea(query, queryArea), searchOptions, (SearchError? searchError, List<Suggestion>? list) {
      if (list != null) {
        emit(state.copyWith(destinationSuggestions: FutureData.completed(list)));
      } else {
        emit(state.copyWith(destinationSuggestions: FutureData.error(searchError.toString())));
      }
    });
  }

  void setDestinationCoordinate(GeoCoordinates coordinates) => emit(state.copyWith(destinationCoordinates: coordinates));

  void calculateRoute() {
    final start = state.startCoordinates;
    final end = state.destinationCoordinates;

    if (start == null || end == null) return;

    final waypoints = [Waypoint(start), Waypoint(end)];

    final truckOptions = _createTruckOptions();

    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (RoutingError? error, List<Route>? routes) {
      if (error != null || routes == null) return;

      final route = routes.first;
      _showRouteOnMap(route);
      emit(state.copyWith(currentRoute: route, hasDirection: true));
    });
  }

  TruckOptions _createTruckOptions() {
    TruckOptions truckOptions = TruckOptions();
    truckOptions.routeOptions.enableTolls = true;

    AvoidanceOptions avoidanceOptions = AvoidanceOptions();
    avoidanceOptions.roadFeatures = [
      RoadFeatures.uTurns,
      RoadFeatures.ferry,
      RoadFeatures.dirtRoad,
      RoadFeatures.tunnel,
      RoadFeatures.carShuttleTrain,
    ];
    // Exclude emission zones to not pollute the air in sensitive inner city areas.
    avoidanceOptions.zoneCategories = [ZoneCategory.environmental];
    truckOptions.avoidanceOptions = avoidanceOptions;
    truckOptions.truckSpecifications = _createTruckSpecifications();

    return truckOptions;
  }

  TruckSpecifications _createTruckSpecifications() {
    TruckSpecifications truckSpecifications = TruckSpecifications();
    // When weight is not set, possible weight restrictions will not be taken into consideration
    // for route calculation. By default, weight is not set.
    // Specify the weight including trailers and shipped goods (if any).
    truckSpecifications.grossWeightInKilograms = MyTruckSpecs.grossWeightInKilograms;
    truckSpecifications.heightInCentimeters = MyTruckSpecs.heightInCentimeters;
    truckSpecifications.widthInCentimeters = MyTruckSpecs.widthInCentimeters;
    // The total length including all trailers (if any).
    truckSpecifications.lengthInCentimeters = MyTruckSpecs.lengthInCentimeters;
    truckSpecifications.weightPerAxleInKilograms = MyTruckSpecs.weightPerAxleInKilograms;
    truckSpecifications.axleCount = MyTruckSpecs.axleCount;
    truckSpecifications.trailerCount = MyTruckSpecs.trailerCount;
    truckSpecifications.truckType = MyTruckSpecs.truckType;
    return truckSpecifications;
  }

  void _showRouteOnMap(Route route) {
    final GeoPolyline polyline = route.geometry;
    late MapPolyline mapPolyline;
    mapPolyline = MapPolyline.withRepresentation(
      polyline,
      MapPolylineSolidRepresentation(
        MapMeasureDependentRenderSize.withSingleSize(RenderSizeUnit.pixels, 30.0),
        AppColorTheme().primary,
        LineCap.round,
      ),
    );
    state.mapController?.mapScene.addMapPolyline(mapPolyline);
    _currentRoutePolyline = mapPolyline;
    _animateToRoute(route);
  }

  void _animateToRoute(Route route) {
    Point2D origin = Point2D(50, 50);
    Size2D sizeInPixels = Size2D(state.mapController!.viewportSize.width - 100, state.mapController!.viewportSize.height - 100);
    Rectangle2D mapViewport = Rectangle2D(origin, sizeInPixels);

    MapCameraUpdate cameraUpdate = MapCameraUpdateFactory.lookAtAreaWithGeoOrientationAndViewRectangle(
      route.boundingBox,
      GeoOrientationUpdate(0.0, 0.0),
      mapViewport,
    );

    MapCameraAnimation animation = MapCameraAnimationFactory.createAnimationFromUpdateWithEasing(
      cameraUpdate,
      Duration(milliseconds: 2000),
      Easing(EasingFunction.outInSine),
    );

    state.mapController!.camera.startAnimation(animation);
  }

  /// 🚗 Start navigation (choose GPS or Simulation)
  void startNavigation({bool simulate = false}) {
    if (state.currentRoute == null) return;
    _visualNavigator?.route = state.currentRoute!;
    _visualNavigator?.startRendering(state.mapController!);

    if (simulate) {
      _simulator = HEREPositioningSimulator();
      _simulator?.startLocating(_visualNavigator!, _navigator!, state.currentRoute!);
      emit(state.copyWith(isNavigating: true, isSimulating: true));
    } else {
      emit(state.copyWith(isNavigating: true, isSimulating: false));
    }
  }

  void _updateCurrentLocationMarker(GeoCoordinates coords) {
    if (_currentLocationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_currentLocationMarker!);
    }
    MapImage userImage = MapImage.withFilePathAndWidthAndHeight(AppIcons.myLocIcon, 40, 40); // add your own icon
    _currentLocationMarker = MapMarker(coords, userImage);
    state.mapController?.mapScene.addMapMarker(_currentLocationMarker!);

    // Center camera
    state.mapController?.camera.lookAtPoint(coords);
    emit(state.copyWith(startCoordinates: coords));
  }

  void stopNavigation() {
    _visualNavigator?.stopRendering();
    _simulator?.stopLocating();
    _locationEngine?.stop();

    // Clear polylines
    if (_currentRoutePolyline != null) {
      state.mapController?.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null;
    }

    // Clear markers
    if (_startMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_startMarker!);
      _startMarker = null;
    }
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    emit(state.copyWith(currentRoute: null, isNavigating: false, isSimulating: false));
  }
}
