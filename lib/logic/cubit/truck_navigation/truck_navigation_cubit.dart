import 'dart:developer';
import 'dart:math' as m;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/animation.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/gestures.dart';
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
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/snacks/snackbar_utils.dart';
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
  MapMarker? _destinationMarker;
  List<MapMarker> _truckRestrictionMarkers = [];
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
        log("Map scene not loaded. Error: ${error.toString()}");
        return;
      }

      // Enable vehicle restrictions and related map features
      _enableMapFeatures(controller);

      controller.gestures.tapListener = TapListener((Point2D touchPoint) {
        if (!state.hasDirection && !state.isNavigating) {
          _handleMapTapForDestination(touchPoint);
        }

        // Use a larger area to include restriction icons
        const double pickRadius = 50;
        final Rectangle2D pickArea = Rectangle2D(
          Point2D(touchPoint.x - pickRadius, touchPoint.y - pickRadius),
          Size2D(pickRadius * 2, pickRadius * 2),
        );

        // Pick from both mapItems (custom markers) and mapContent (restriction icons)
        final filter = MapSceneMapPickFilter([
          MapSceneMapPickFilterContentType.mapItems,
          MapSceneMapPickFilterContentType.mapContent,
        ]);

        controller.pick(filter, pickArea, (MapPickResult? result) {
          if (result == null) return;

          // Handle custom markers (truck restriction warnings)
          if ((result.mapItems?.markers ?? []).isNotEmpty) {
            final MapMarker? pickedMarker =
                result.mapItems?.markers.firstOrNull;
            if (pickedMarker != null) {
              final String message =
                  pickedMarker.metadata?.getString("warning_message") ?? '';
              if (message.isNotEmpty) {
                SnackbarUtils.showWarningSnackBar(
                  navigatorKey.currentContext!,
                  message,
                );
              }
            }
          }

          // Handle vehicle restrictions from map content
          // final vehicleRestrictions = result.mapContent?.vehicleRestrictions;
          // if (vehicleRestrictions != null && vehicleRestrictions.isNotEmpty) {
          //   final restriction = vehicleRestrictions.first;
          //   final coords = restriction.coordinates;
          //   SnackbarUtils.showWarningSnackBar(
          //     navigatorKey.currentContext!,
          //     "Vehicle restriction at ${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}",
          //   );
          // }
        });
      });
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

    // Set up transport profile for VisualNavigator to enable truck restriction warnings
    _setupTransportProfile();
  }

  // Set up transport profile for VisualNavigator
  void _setupTransportProfile() {
    if (_visualNavigator == null) return;

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        log("Context not available for transport profile setup");
        return;
      }

      final TruckSpecificationState specs = context
          .read<TruckSpecificationsCubit>()
          .state;

      final TransportProfile transportProfile = TransportProfile();
      final VehicleProfile vehicleProfile = VehicleProfile(VehicleType.truck);

      vehicleProfile.grossWeightInKilograms = specs.grossWeightInKilograms;
      vehicleProfile.heightInCentimeters = specs.heightInCentimeters;
      vehicleProfile.widthInCentimeters = specs.widthInCentimeters;
      vehicleProfile.lengthInCentimeters = specs.lengthInCentimeters;
      vehicleProfile.weightPerAxleInKilograms = specs.weightPerAxleInKilograms;
      vehicleProfile.axleCount = specs.axleCount;
      vehicleProfile.trailerCount = specs.trailerCount;
      vehicleProfile.truckType = specs.truckType;

      transportProfile.vehicleProfile = vehicleProfile;
      _visualNavigator!.trackingTransportProfile = transportProfile;

      log("Transport profile set up for truck specifications");
    } catch (e) {
      log("Error setting up transport profile: $e");
    }
  }

  // Update transport profile when truck specifications change
  void updateTransportProfile() {
    _setupTransportProfile();
  }

  // Enable map features including vehicle restrictions
  void _enableMapFeatures(HereMapController controller) {
    final Map<String, String> mapFeatures = {
      MapFeatures.trafficFlow: MapFeatureModes.trafficFlowWithFreeFlow,
      MapFeatures.trafficIncidents: MapFeatureModes.defaultMode,
      MapFeatures.safetyCameras: MapFeatureModes.defaultMode,
      MapFeatures.vehicleRestrictions: MapFeatureModes.defaultMode,
      MapFeatures.environmentalZones: MapFeatureModes.defaultMode,
      MapFeatures.congestionZones: MapFeatureModes.defaultMode,
    };

    controller.mapScene.enableFeatures(mapFeatures);
    log("Vehicle restrictions and map features enabled");
  }

  void changeMapScheme(MapScheme scheme) {
    if (state.mapController == null) return;

    state.mapController?.mapScene.loadSceneForMapScheme(scheme, (error) {
      if (error != null) {
        print("Failed to change map scheme: $error");
        return;
      }
      print("Map scheme changed to $scheme");
      // Re-enable map features after scheme change
      if (state.mapController != null) {
        _enableMapFeatures(state.mapController!);
      }
    });
  }

  double calculateDistanceInMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371000; // meters

    final double dLat = _degreesToRadians(endLat - startLat);
    final double dLng = _degreesToRadians(endLng - startLng);

    final double a =
        m.sin(dLat / 2) * m.sin(dLat / 2) +
        m.cos(_degreesToRadians(startLat)) *
            m.cos(_degreesToRadians(endLat)) *
            m.sin(dLng / 2) *
            m.sin(dLng / 2);

    final double c = 2 * m.atan2(m.sqrt(a), m.sqrt(1 - a));

    return earthRadius * c; // in meters
  }

  double _degreesToRadians(double degree) => degree * m.pi / 180.0;

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
    emit(
      state.copyWith(
        startCoordinates: coords,
        // currentPlace: FutureData.loading(),
      ),
    );
    getCurrentLocationPlace();
    getNearbyTruckStops();
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

  Future getNearbyTruckStops() async {
    if (state.startCoordinates == null) {
      emit(
        state.copyWith(
          nearbyTruckStops: FutureData.error(
            "Unable to retrieve nearby places because the current location could not be determined.",
          ),
        ),
      );
      return;
    }

    final SearchEngine searchEngine = SearchEngine();

    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 3;

    TextQueryArea queryArea = TextQueryArea.withCenter(state.startCoordinates!);

    final TextQuery query = TextQuery.withArea("truck stop", queryArea);

    searchEngine.searchByText(query, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        emit(
          state.copyWith(
            nearbyTruckStops: FutureData.error(
              "Unable to retrieve nearby places because $error",
            ),
          ),
        );

        return;
      }

      if (places != null && places.isNotEmpty) {
        final List<Place> _list = [];

        for (final place in places) {
          _list.add(place);
        }
        emit(state.copyWith(nearbyTruckStops: FutureData.completed(_list)));
      } else {
        emit(
          state.copyWith(
            nearbyTruckStops: FutureData.error("No nearby places found"),
          ),
        );
      }
    });
  }

  void startListeningToLocation() async {
    if (AppKeys().isSimulation) {
      setInitialLocation(AppKeys().startCoordinates);
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
            if (state.startCoordinates != null) {
              final double distance = calculateDistanceInMeters(
                state.startCoordinates!.latitude,
                state.startCoordinates!.longitude,
                coords.latitude,
                coords.longitude,
              );
              print("has Distance of ${distance} > 10 ${distance > 10}");
              if (distance > 10) {
                _updateCurrentLocationMarker(coords);
                return;
              }
            } else {
              _updateCurrentLocationMarker(coords);
            }
          }
          if (state.isNavigating) {
            _visualNavigator?.onLocationUpdated(location);
            _navigator?.onLocationUpdated(location);
          }
        }),
      );

      _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);
    }
  }

  Future<void> getCurrentLocationPlace() async {
    if (state.startCoordinates == null) {
      emit(
        state.copyWith(
          nearbyTruckStops: FutureData.error(
            "Unable to retrieve details because the current location could not be determined.",
          ),
        ),
      );
      return;
    }

    final GeoCoordinates currentCoords = state.startCoordinates!;
    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    _searchEngine.searchByCoordinates(currentCoords, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        log("Reverse geocoding failed: $error");
        return;
      }
      if (places != null && places.isNotEmpty) {
        emit(state.copyWith(currentPlace: FutureData.completed(places.first)));
      } else {
        emit(
          state.copyWith(
            currentPlace: FutureData.error(
              "No details available of current location",
            ),
          ),
        );
      }
    });
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
    emit(
      state.copyWith(
        selectedSuggestion: suggestion,
        destinationCoordinates: suggestion.place?.geoCoordinates,
        // hasTapDestination: true,
        // tappedPlace: FutureData<Place>.completed(suggestion.place),
      ),
    );
    confirmDestination();
    setDestinationMarkerFromSuggestion();
  }

  void confirmDestination() {
    if (state.selectedSuggestion != null) {
      final List<LocationPoint> _list = [];
      _list.add(
        LocationPoint<Place>(
          place: state.currentPlace!.data!,
          pointType: LocationPointType.starting,
        ),
      );
      _list.add(
        LocationPoint<Place>(
          place: state.selectedSuggestion!.place!,
          pointType: LocationPointType.destination,
        ),
      );

      emit(
        state.copyWith(
          locationPoints: _list,
          hasTapDestination: true,
          tappedPlace: FutureData<Place>.completed(
            state.selectedSuggestion?.place,
          ),
        ),
      );
      // setDestinationMarkerFromSuggestion();
    }
  }

  void setDestinationMarkerFromSuggestion() {
    if (state.destinationCoordinates == null) return;
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    MapImage destIcon = MapImage.withFilePathAndWidthAndHeight(
      AppImages.greenMapPin,
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
    GeoCoordinates? start = state.locationPoints?.firstOrNull?.geoCoordinates;
    GeoCoordinates? end = state.locationPoints?.lastOrNull?.geoCoordinates;

    if (start == null || end == null) return;

    // Update transport profile before calculating route to ensure restrictions are accurate
    _setupTransportProfile();

    final waypoints = [Waypoint(start), Waypoint(end)];

    final truckOptions = _createTruckOptions();

    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
      RoutingError? error,
      List<Route>? routes,
    ) {
      if (error != null || routes == null) return;

      final route = routes.first;
      _showRouteOnMap(route);
      _processTruckRestrictionWarnings(route);
      emit(state.copyWith(currentRoute: route, hasDirection: true));
    });
  }

  TruckOptions _createTruckOptions() {
    TruckSpecificationState mySpecs = navigatorKey.currentContext!
        .read<TruckSpecificationsCubit>()
        .state;
    TruckOptions truckOptions = TruckOptions();
    truckOptions.routeOptions.enableTolls = true;

    truckOptions.avoidanceOptions = _createTruckAvoidanceOptions();

    truckOptions.truckSpecifications = _createTruckSpecifications(mySpecs);

    if (mySpecs.hazardousMaterial != '-') {
      truckOptions.hazardousMaterials = mapHazardousMaterial(
        mySpecs.hazardousMaterial,
      );
    }

    return truckOptions;
  }

  List<HazardousMaterial> mapHazardousMaterial(String selected) {
    switch (selected) {
      case "Explosives":
        return [HazardousMaterial.explosive];

      case "Gases":
        return [HazardousMaterial.gas];

      case "Flammable Liquids":
        return [HazardousMaterial.flammable];

      case "Flammable Solids":
        return [HazardousMaterial.combustible];

      case "Organic":
        return [HazardousMaterial.organic];

      case "Poison & Toxic":
        return [HazardousMaterial.poison];

      case "Radioactive":
        return [HazardousMaterial.radioactive];

      case "Corrosive":
        return [HazardousMaterial.corrosive];

      case "Misc. Dangerous":
        return [HazardousMaterial.other];

      default:
        return [];
    }
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

  TruckSpecifications _createTruckSpecifications(
    TruckSpecificationState mySpecs,
  ) {
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
    if (_currentRoutePolyline != null) {
      state.mapController?.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null;
      _clearTruckPreviousMarkers();
    }

    _currentRoutePolyline = mapPolyline;
    state.mapController?.mapScene.addMapPolyline(mapPolyline);
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
    setupTruckRestrictionWarnings();
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

  void clearCurrentRouteDetail({bool removeDestination = true}) {
    // Clear polylines
    if (removeDestination && _destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    if (_currentRoutePolyline != null) {
      state.mapController?.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null;
    }

    _clearTruckPreviousMarkers();

    emit(
      state.copyWith(
        destinationSuggestions: FutureData<List<Suggestion>>.initial(),
        selectedSuggestion: removeDestination ? 'null' : null,
        destinationCoordinates: removeDestination ? 'null' : null,
        currentRoute: 'null',
        hasDirection: false,
        isNavigating: false,
        destinationFromRecent: 'null',
        hasdestinationFromRecent: false,
        locationPoints: [],
        hasTapDestination: false,
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

  void setupTruckRestrictionWarnings() {
    _visualNavigator
        ?.truckRestrictionsWarningListener = TruckRestrictionsWarningListener((
      List<TruckRestrictionWarning> warnings,
    ) {
      if (warnings.isEmpty) return;

      for (final warning in warnings) {
        // Determine distance state:
        final DistanceType distanceType = warning.distanceType;
        final String distanceLabel = _distanceTypeLabel(distanceType);

        // Build description depending on which restriction field is present.
        String description = "Truck restriction";

        if (warning.weightRestriction != null) {
          final wr = warning.weightRestriction!;
          final int kg = wr.valueInKilograms;
          // convert to tons with one decimal:
          final double tons = (kg / 1000.0 * 10).round() / 10;
          description = "Weight limit: ${tons} t";
        } else if (warning.dimensionRestriction != null) {
          final dr = warning.dimensionRestriction!;
          final int valueCm = dr.valueInCentimeters;
          String dimType = "Dimension";
          if (dr.type == DimensionRestrictionType.truckHeight)
            dimType = "Height";
          if (dr.type == DimensionRestrictionType.truckLength)
            dimType = "Length";
          if (dr.type == DimensionRestrictionType.truckWidth) dimType = "Width";

          final double meters = (valueCm / 100.0 * 10).round() / 10;
          description = "$dimType limit: ${meters} m";
        } else if (warning.hazardousMaterials.isNotEmpty) {
          final hazardList = warning.hazardousMaterials
              .map((h) => h.name.toString().split('.').last)
              .join(', ');
          description = "Hazardous goods not allowed: $hazardList";
        } else if (warning.trailerCount != null) {
          description =
              "Trailer restriction: min ${warning.trailerCount!.min}, max ${warning.trailerCount!.max ?? 'no max'}";
        } else {
          description = "Truck restriction ahead";
        }
        String distanceInfo = "";
        try {
          distanceInfo = " in ${warning.distanceInMeters.toInt()} m";
        } catch (_) {}

        final message = "$description $distanceLabel$distanceInfo";
        log("🚨 $message");
        SnackbarUtils.showWarningSnackBar(
          navigatorKey.currentContext!,
          message,
        );
      }
    });
  }

  String _distanceTypeLabel(DistanceType distanceType) {
    switch (distanceType) {
      case DistanceType.ahead:
        return "ahead";
      case DistanceType.reached:
        return "reached";
      case DistanceType.passed:
        return "passed";
      default:
        return "";
    }
  }

  void _processTruckRestrictionWarnings(Route route) async {
    for (final section in route.sections) {
      for (final notice in section.sectionNotices) {
        final message = notice.code.name.toLowerCase();
        if (message.contains("restriction") ||
            message.contains("height") ||
            message.contains("weight") ||
            message.contains("width") ||
            message.contains("tunnel") ||
            message.contains("hazardous") ||
            message.contains("bridge") ||
            message.contains("limit")) {
          print("⚠️ Truck Restriction Found: ${notice.code.name}");

          // Get best coordinate (section start or geometry)
          final GeoCoordinates location =
              section.departurePlace.originalCoordinates ??
              section.geometry.vertices.first;

          // Add visual marker
          await _addWarningMarker(location, notice.code.name);
        }
      }
    }
  }

  /// Helper to create custom warning marker on map.
  Future<void> _addWarningMarker(
    GeoCoordinates coordinates,
    String message,
  ) async {
    final mapImage = MapImage.withFilePathAndWidthAndHeight(
      'assets/images/truck_warning.png',
      70,
      70,
    );

    final marker = MapMarker(coordinates, mapImage);

    // Add marker metadata (so you can handle tap events)
    final metadata = Metadata();
    metadata.setString("warning_message", message);
    marker.metadata = metadata;

    state.mapController?.mapScene.addMapMarker(marker);
    _truckRestrictionMarkers.add(marker);
  }

  void _clearTruckPreviousMarkers() {
    for (final marker in _truckRestrictionMarkers) {
      state.mapController?.mapScene.removeMapMarker(marker);
    }
    _truckRestrictionMarkers.clear();
  }

  selectRecentAsDestination(RecentSearchModel recent) {
    final GeoCoordinates geoCoordinates = GeoCoordinates(
      recent.latitude,
      recent.longitude,
    );

    final List<LocationPoint> _list = [];
    _list.add(
      LocationPoint<Place>(
        place: state.currentPlace!.data!,
        pointType: LocationPointType.starting,
      ),
    );
    _list.add(
      LocationPoint<RecentSearchModel>(
        place: recent,
        pointType: LocationPointType.destination,
      ),
    );

    // Set destination coordinates
    emit(
      state.copyWith(
        locationPoints: _list,
        hasTapDestination: true,
        hasdestinationFromRecent: true,
        destinationFromRecent: recent,
        destinationCoordinates: geoCoordinates,
      ),
    );

    // Add destination marker
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    MapImage destIcon = MapImage.withFilePathAndWidthAndHeight(
      AppImages.greenMapPin,
      60,
      100,
    );

    _destinationMarker = MapMarker(geoCoordinates, destIcon);
    state.mapController?.mapScene.addMapMarker(_destinationMarker!);
  }

  void _handleMapTapForDestination(Point2D touchPoint) {
    // Convert screen coordinates to geo coordinates
    final geoCoordinates = state.mapController?.viewToGeoCoordinates(
      touchPoint,
    );
    if (geoCoordinates == null) return;

    // Set destination coordinates
    emit(
      state.copyWith(
        hasTapDestination: true,
        destinationCoordinates: geoCoordinates,
      ),
    );

    // Add destination marker
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    MapImage destIcon = MapImage.withFilePathAndWidthAndHeight(
      AppImages.greenMapPin,
      60,
      100,
    );

    _destinationMarker = MapMarker(geoCoordinates, destIcon);
    state.mapController?.mapScene.addMapMarker(_destinationMarker!);

    // Reverse geocode to get place details
    _reverseGeocodeDestination(geoCoordinates);
  }

  void _reverseGeocodeDestination(GeoCoordinates coords) {
    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    // First reverse geocode for place details
    _searchEngine.searchByCoordinates(coords, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        log("Reverse geocoding failed: $error");
        emit(
          state.copyWith(
            tappedPlace: FutureData.error("Unable to get location details"),
          ),
        );
        return;
      }
      if (places != null && places.isNotEmpty) {
        final List<LocationPoint> _list = [];
        _list.add(
          LocationPoint<Place>(
            place: state.currentPlace!.data!,
            pointType: LocationPointType.starting,
          ),
        );
        _list.add(
          LocationPoint<Place>(
            place: places.first,
            pointType: LocationPointType.destination,
          ),
        );
        emit(
          state.copyWith(
            locationPoints: _list,
            tappedPlace: FutureData.completed(places.first),
          ),
        );
      } else {
        emit(
          state.copyWith(
            tappedPlace: FutureData.error(
              "No details available for this location",
            ),
          ),
        );
      }
    });
  }

  void removeTapDestination() {
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    clearCurrentRouteDetail();
    emit(
      state.copyWith(
        hasTapDestination: false,
        hasdestinationFromRecent: false,
        destinationCoordinates: 'null',
        destinationFromRecent: 'null',
        selectedSuggestion: 'null',
        tappedPlace: FutureData<Place>.initial(),
      ),
    );
  }

  void changeLocationPointOrder(oldIndex, newIndex) {
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    if (_list.isEmpty) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final removed = _list.removeAt(oldIndex);
    _list.insert(newIndex, removed);
    emit(state.copyWith(locationPoints: _list));
  }

  void addStop(dynamic place) {
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    if (_list.isEmpty) return;

    final item = place is Place
        ? LocationPoint<Place>(place: place, pointType: LocationPointType.stop)
        : LocationPoint<RecentSearchModel>(
            place: place,
            pointType: LocationPointType.stop,
          );

    _list.insert(state.locationPoints!.length - 1, item);
    emit(state.copyWith(locationPoints: _list));
  }

  void deleteStop(int index) {
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    if (_list.isEmpty) return;
    if (_list.length <= 2) return;
    _list.removeAt(index);
    emit(state.copyWith(locationPoints: _list));
  }
}
