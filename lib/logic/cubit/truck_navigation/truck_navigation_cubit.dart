import 'dart:developer';

import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;
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
import 'package:ommo/app/app.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/map_sdk/HEREPositioningSimulator.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/theme/theme.dart';

class TruckNavigationCubit extends Cubit<TruckNavigationState> {
  TruckNavigationCubit() : super(TruckNavigationState());

  final RoutingEngine _routingEngine = RoutingEngine();
  final SearchEngine _searchEngine = SearchEngine();
  final widgets.DraggableScrollableController navigationSheetScrollController =
      widgets.DraggableScrollableController();
  VisualNavigator? _visualNavigator;
  Navigator? _navigator;
  LocationEngine? _locationEngine;
  HEREPositioningSimulator? _simulator;
  MapPolyline? _currentRoutePolyline;
  MapMarker? _currentLocationMarker;
  MapMarker? _startMarker;
  MapMarker? _destinationMarker;
  final loc.Location _location = loc.Location();

  // Setters
  void setInitialLocation(GeoCoordinates coords) {
    emit(state.copyWith(isMapLoading: false, startCoordinates: coords));
    _updateCurrentLocationMarker(coords);
  }

  // Map Functions
  void onMapCreated(HereMapController controller) {
    emit(state.copyWith(mapController: controller));
    controller.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (error) {
      if (error != null) {
        print("Map scene not loaded. Error: ${error.toString()}");
        return;
      }
    });
    if (state.startCoordinates != null) {
      setInitialLocation(state.startCoordinates!);
      const double distanceToEarthInMeters = 8000;
      MapMeasure mapMeasureZoom = MapMeasure(
        MapMeasureKind.distanceInMeters,
        distanceToEarthInMeters,
      );
      controller.camera.lookAtPointWithMeasure(
        state.startCoordinates!,
        mapMeasureZoom,
      );
    }
    _visualNavigator = VisualNavigator();
    _navigator = Navigator();
  }

  void _updateCurrentLocationMarker(GeoCoordinates coords) {
    if (_currentLocationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_currentLocationMarker!);
    }
    MapImage userImage = MapImage.withFilePathAndWidthAndHeight(
      AppIcons.myLocIcon,
      40,
      40,
    ); // add your own icon
    _currentLocationMarker = MapMarker(coords, userImage);
    state.mapController?.mapScene.addMapMarker(_currentLocationMarker!);

    // // Center camera
    // if (!state.cameraControlledByNavigator) {
    //   state.mapController?.camera.lookAtPoint(coords);
    // }
    emit(state.copyWith(startCoordinates: coords));
  }

  void mapZoomIn(material.BuildContext context) {
    Point2D center = Point2D(context.screenWidth / 2, context.screenHeight / 2);
    state.mapController?.camera.zoomBy(2.0, center);
  }

  void mapZoomOut(material.BuildContext context) {
    Point2D center = Point2D(context.screenWidth / 2, context.screenHeight / 2);
    state.mapController?.camera.zoomBy(0.5, center);
  }

  void focusOnCurrentLocation({double distanceInMeters = 1000}) {
    final coords = state.startCoordinates;
    final controller = state.mapController;

    if (coords == null || controller == null) return;

    final mapMeasure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      distanceInMeters,
    );

    controller.camera.lookAtPointWithMeasure(coords, mapMeasure);
  }

  // Location Handlers
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
    if (AppKeys().isSimulation) {
      setInitialLocation(GeoCoordinates(40.7064783, -74.00585));
    } else {
      _locationEngine = LocationEngine();
      _locationEngine?.confirmHEREPrivacyNoticeInclusion();
      final GeoCoordinates? initialCoordinates = await _getCurrentLocation();

      if (initialCoordinates != null) {
        setInitialLocation(initialCoordinates);
      }

      _locationEngine?.addLocationListener(
        LocationListener((Location location) {
          final GeoCoordinates coords = location.coordinates;
          log("Location recieved $coords");
          if (!state.isNavigating) {
            _updateCurrentLocationMarker(coords);
          }
          if (state.isNavigating) {
            _visualNavigator?.onLocationUpdated(location);
            _navigator?.onLocationUpdated(location);
          }
        }),
      );

      _locationEngine?.startWithLocationAccuracy(
        LocationAccuracy.bestAvailable,
      );
    }
  }

  /// Routing and Navigation Functions
  void searchPlaces(String query) {
    if (state.startCoordinates == null) return;
    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 5;

    TextQueryArea queryArea = TextQueryArea.withCenter(state.startCoordinates!);

    _searchEngine.suggestByText(
      TextQuery.withArea(query, queryArea),
      searchOptions,
      (SearchError? searchError, List<Suggestion>? list) {
        if (list != null) {
          emit(
            state.copyWith(destinationSuggestions: FutureData.completed(list)),
          );
        } else {
          emit(
            state.copyWith(
              destinationSuggestions: FutureData.error(searchError.toString()),
            ),
          );
        }
      },
    );
  }

  void setDestinationCoordinate(Suggestion suggestion) {
    emit(state.copyWith(selectedSuggestion: suggestion));
    setDestinationMarkerFromSuggestion();
  }

  void setDestinationMarkerFromSuggestion() {
    if (state.destinationCoordinates == null) return;
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    MapImage destIcon = MapImage.withFilePathAndWidthAndHeight(
      AppImages.greenMarker,
      60,
      100,
    );
    _destinationMarker = MapMarker(state.destinationCoordinates!, destIcon);
    state.mapController?.mapScene.addMapMarker(_destinationMarker!);
    focusDestinationWithOffset(state.destinationCoordinates!);
  }

  void focusDestinationWithOffset(
    GeoCoordinates coords, {
    double offsetPixels = 90,
  }) {
    const double zoomDistance = 3000;
    MapMeasure measure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      zoomDistance,
    );

    // Get screen size
    final screenSize = state.mapController!.viewportSize;

    // Convert pixel offset (100px) into meters at current zoom
    double metersPerPixel = zoomDistance / screenSize.height;
    double offsetMeters = metersPerPixel * offsetPixels;

    // Move the target slightly south (negative latitude delta)
    GeoCoordinates shiftedCoords = GeoCoordinates(
      coords.latitude - (offsetMeters / 111000), // approx meters -> degrees
      coords.longitude,
    );

    state.mapController?.camera.lookAtPointWithMeasure(shiftedCoords, measure);
  }

  void calculateRoute() {
    final start = state.startCoordinates;
    final end = state.destinationCoordinates;

    if (start == null || end == null) return;

    final waypoints = [Waypoint(start), Waypoint(end)];

    final truckOptions = _createTruckOptions();

    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
      RoutingError? error,
      List<Route>? routes,
    ) {
      if (error != null || routes == null) return;

      final route = routes.first;
      _showRouteOnMap(route);
      emit(state.copyWith(currentRoute: route, hasDirection: true));
    });
  }

  TruckOptions _createTruckOptions() {
    TruckOptions truckOptions = TruckOptions();
    truckOptions.routeOptions.enableTolls = true;
    truckOptions.avoidanceOptions = _createTruckAvoidanceOptions();
    truckOptions.truckSpecifications = _createTruckSpecifications();

    return truckOptions;
  }

  AvoidanceOptions _createTruckAvoidanceOptions() {
    final myState = navigatorKey.currentContext!
        .read<TruckSpecificationsCubit>()
        .state;

    final avoidance = myState.avoidance;

    AvoidanceOptions avoidanceOptions = AvoidanceOptions();

    List<RoadFeatures> roadFeatures = [];

    if (avoidance['ferries'] == true) {
      roadFeatures.add(RoadFeatures.ferry);
    }
    if (avoidance['unpaved_roads'] == true) {
      roadFeatures.add(RoadFeatures.dirtRoad);
    }
    if (avoidance['tunnels'] == true) {
      roadFeatures.add(RoadFeatures.tunnel);
    }
    if (avoidance['highways'] == true) {
      roadFeatures.add(RoadFeatures.controlledAccessHighway);
    }
    if (avoidance['tolls'] == true) {
      roadFeatures.add(RoadFeatures.tollRoad);
    }

    avoidanceOptions.roadFeatures = roadFeatures;

    avoidanceOptions.zoneCategories = [ZoneCategory.environmental];

    return avoidanceOptions;
  }

  TruckSpecifications _createTruckSpecifications() {
    TruckSpecificationState? mySpecs = navigatorKey.currentContext!
        .read<TruckSpecificationsCubit>()
        .state;

    TruckSpecifications truckSpecifications = TruckSpecifications();
    // When weight is not set, possible weight restrictions will not be taken into consideration
    // for route calculation. By default, weight is not set.
    // Specify the weight including trailers and shipped goods (if any).
    truckSpecifications.grossWeightInKilograms = mySpecs.grossWeightInKilograms;
    truckSpecifications.heightInCentimeters = mySpecs.heightInCentimeters;
    truckSpecifications.widthInCentimeters = mySpecs.widthInCentimeters;
    // The total length including all trailers (if any).
    truckSpecifications.lengthInCentimeters = mySpecs.lengthInCentimeters;
    truckSpecifications.weightPerAxleInKilograms =
        mySpecs.weightPerAxleInKilograms;
    truckSpecifications.axleCount = mySpecs.axleCount;
    truckSpecifications.trailerCount = mySpecs.trailerCount;
    truckSpecifications.truckType = mySpecs.truckType;
    return truckSpecifications;
  }

  void _showRouteOnMap(Route route) {
    final GeoPolyline polyline = route.geometry;
    late MapPolyline mapPolyline;
    mapPolyline = MapPolyline.withRepresentation(
      polyline,
      MapPolylineSolidRepresentation(
        MapMeasureDependentRenderSize.withSingleSize(
          RenderSizeUnit.pixels,
          30.0,
        ),
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
    Size2D sizeInPixels = Size2D(
      state.mapController!.viewportSize.width - 100,
      state.mapController!.viewportSize.height - 100,
    );
    Rectangle2D mapViewport = Rectangle2D(origin, sizeInPixels);

    MapCameraUpdate cameraUpdate =
        MapCameraUpdateFactory.lookAtAreaWithGeoOrientationAndViewRectangle(
          route.boundingBox,
          GeoOrientationUpdate(0.0, 0.0),
          mapViewport,
        );

    MapCameraAnimation animation =
        MapCameraAnimationFactory.createAnimationFromUpdateWithEasing(
          cameraUpdate,
          Duration(milliseconds: 2000),
          Easing(EasingFunction.outInSine),
        );

    state.mapController!.camera.startAnimation(animation);
  }

  void startNavigation() {
    if (state.currentRoute == null) return;

    _visualNavigator?.route = state.currentRoute!;
    _visualNavigator?.startRendering(state.mapController!);

    setupManeuverUpdates();
    if (AppKeys().isSimulation) {
      _locationEngine?.stop();

      emit(
        state.copyWith(isNavigating: true, cameraControlledByNavigator: true),
      );
      _simulator = HEREPositioningSimulator();

      final LocationListener navigatorForwarder = LocationListener((
        Location location,
      ) {
        _navigator?.onLocationUpdated(location);
      });
      _simulator?.startLocating(
        _visualNavigator!,
        navigatorForwarder,
        state.currentRoute!,
      );
    } else {
      emit(
        state.copyWith(isNavigating: true, cameraControlledByNavigator: true),
      );
    }
  }

  minimizeNavigationSheetOn() {
    if (navigationSheetScrollController.isAttached) {
      navigationSheetScrollController.animateTo(
        0.26,
        duration: const Duration(milliseconds: 300),
        curve: widgets.Curves.easeOut,
      );
    } else {
      log("navigationSheetScrollController is not attached");
    }
  }

  void showRouteDisableCameraControlByNavigator() {
    _visualNavigator?.cameraBehavior = null;
    emit(state.copyWith(cameraControlledByNavigator: false));
  }

  void resumeCameraControlByNavigator() {
    _visualNavigator?.cameraBehavior = DynamicCameraBehavior();
    emit(state.copyWith(cameraControlledByNavigator: true));
  }

  void toggleCameraControll() {
    if (state.cameraControlledByNavigator) {
      showRouteDisableCameraControlByNavigator();
    } else {
      resumeCameraControlByNavigator();
    }
  }

  void stopNavigation() {
    _visualNavigator?.stopRendering();

    if (AppKeys().isSimulation) {
      _simulator?.stopLocating();
      _simulator = null;
    }
    emit(state.copyWith(cameraControlledByNavigator: false));

    if (_locationEngine != null && !(AppKeys().isSimulation)) {
      _locationEngine?.startWithLocationAccuracy(
        LocationAccuracy.bestAvailable,
      );
    }

    clearCurrentRouteDetail();
  }

  void clearCurrentRouteDetail() {
    // Clear polylines
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }
    if (_currentRoutePolyline != null) {
      state.mapController?.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null;
    }
    emit(
      state.copyWith(
        destinationSuggestions: FutureData<List<Suggestion>>.initial(),
        selectedSuggestion: 'null',
        currentRoute: 'null',
        hasDirection: false,
        isNavigating: false,
      ),
    );
  }

  void setupManeuverUpdates() {
    if (_visualNavigator == null) return;
    _visualNavigator!.routeProgressListener = RouteProgressListener((
      RouteProgress progress,
    ) {
      if (progress.maneuverProgress.isEmpty) {
        emit(state.copyWith(maneuverProgress: "null"));
      } else {
        emit(state.copyWith(maneuverProgress: progress.maneuverProgress.first));
      }
    });
  }
}
