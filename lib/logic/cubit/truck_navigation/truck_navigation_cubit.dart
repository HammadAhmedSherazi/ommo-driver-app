import 'dart:developer';
import 'dart:math' as m;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
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
import 'package:ommo/logic/cubit/truck_stops/truck_stop_cubit.dart';
import 'package:ommo/map_sdk/HEREPositioningSimulator.dart';
import 'package:ommo/models/location_point_model.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';
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
  Map<int, MapMarker> _stopMarkers = {};
  List<MapMarker> _truckRestrictionMarkers = [];
  final loc.Location _location = loc.Location();
  bool isFirstTimeLocationGet = true;

  Future<MapImage> _createStopMarkerImage(int index) async {
    const double size = 70.0;
    const double borderWidth = 5.0;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final ui.Offset center = ui.Offset(size / 2, size / 2);

    final ui.Paint borderPaint = ui.Paint()
      ..color = AppColorTheme().primary
      ..style = ui.PaintingStyle.fill;

    final ui.Paint fillPaint = ui.Paint()
      ..color = ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    // Draw border circle (outer)
    canvas.drawCircle(center, size / 2, borderPaint);

    // Draw inner circle (fill)
    canvas.drawCircle(center, (size / 2) - borderWidth, fillPaint);

    // Draw text
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 30.0,
        fontWeight: ui.FontWeight.bold,
      ),
    );

    paragraphBuilder.pushStyle(ui.TextStyle(color: ui.Color(0xFF000000)));
    paragraphBuilder.addText('$index');

    final ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size));

    canvas.drawParagraph(
      paragraph,
      ui.Offset(0, center.dy - paragraph.height / 2),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return MapImage.withPixelDataAndImageFormat(
      byteData!.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

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

      // adding drop pin feature to the map to set destination
      controller.gestures.longPressListener = LongPressListener((
        GestureState gestureState,
        Point2D touchPoint,
      ) {
        if (gestureState == GestureState.end &&
            !state.hasDirection &&
            !state.isNavigating) {
          final GeoCoordinates? geoCoordinates = state.mapController
              ?.viewToGeoCoordinates(touchPoint);
          _handleMapTapForDestination(geoCoordinates);
        }
      });
    });

    // add listener to show warning marker detials
    controller.gestures.tapListener = TapListener((Point2D touchPoint) {
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
        log("result: $result");

        if (result == null) return;

        if (state.isNavigating) {
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
        } else if (!state.isNavigating && !state.hasDirection) {
          final Map<String, Place> placeDataMap =
              navigatorKey.currentContext
                  ?.read<TruckStopCubit>()
                  .placeDataMap ??
              {};
          // Check if a place marker was tapped
          if ((result.mapItems?.markers ?? []).isNotEmpty) {
            final MapMarker? pickedMarker =
                result.mapItems?.markers.firstOrNull;
            if (pickedMarker != null) {
              final String? placeId = pickedMarker.metadata?.getString(
                "place_id",
              );
              if (placeDataMap.isEmpty) return;
              if (placeId != null && placeDataMap.containsKey(placeId)) {
                final Place place = placeDataMap[placeId]!;
                navigatorKey.currentContext
                    ?.read<TruckStopCubit>()
                    .showBusinessOverviewModal(place);
                return;
              }
            }
          }

          // Handle regular place picks
          final PickedPlace? pickedPlace =
              result.mapContent?.pickedPlaces.firstOrNull;
          if (pickedPlace == null) return;
          _handlePickedPlaceForDestination(pickedPlace);
        }
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
    if (isFirstTimeLocationGet) {
      isFirstTimeLocationGet = false;
      focusOnCurrentLocation();
    }
    getCurrentLocationPlace();
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
              print("has Distance of $distance > 10 ${distance > 10}");
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
            checkNextTarget(coords);
          }
        }),
      );

      _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);
    }
  }

  void checkNextTarget(GeoCoordinates coords) {
    if ((state.locationPoints ?? []).length > 2) {
      final hasAfterNext =
          state.nextTargetIndex < (state.locationPoints!.length - 1);
      if (!hasAfterNext) return;
      final GeoCoordinates? nextStop =
          state.locationPoints?[state.nextTargetIndex].geoCoordinates;
      if (nextStop == null) return;
      final double stopDistance = calculateDistanceInMeters(
        nextStop.latitude,
        nextStop.longitude,
        coords.latitude,
        coords.longitude,
      );
      if (stopDistance < 40) {
        final _nextTargetIndex = state.nextTargetIndex + 1;
        emit(state.copyWith(nextTargetIndex: _nextTargetIndex));
      }
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
    if (query == '') {
      emit(state.copyWith(destinationSuggestions: FutureData.completed([])));
      return;
    }

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

  void selectSuggestionAsDestination(Suggestion suggestion) {
    if (suggestion.place?.isBusiness == true) {
      searchBusinessDetailsByPlaceId(
        suggestion.place?.id,
        (place) => setDestination(place),
        (e) => setDestination(suggestion.place),
      );
    } else {
      setDestination(suggestion.place);
    }
  }

  void selectBusinessSuggestionAsDestination(Place place) {
    try {
      if (place.isBusiness == true) {
        searchBusinessDetailsByPlaceId(
          place.id,
          (place) => setDestination(place),
          (e) => setDestination(place),
        );
      } else {
        setDestination(place);
      }
    } catch (e) {
      print("bussiness suggestion error  $e");
    }
  }

  void setDestination(Place? place) {
    if (place == null) return;
    final destinationPoint = LocationPoint(
      place: place,
      pointType: LocationPointType.destination,
    );

    final List<LocationPoint> _list = [];
    _list.add(
      LocationPoint(
        place: state.currentPlace!.data!,
        isMyLocation: true,
        pointType: LocationPointType.starting,
      ),
    );
    _list.add(destinationPoint);

    emit(
      state.copyWith(
        selectedSuggestion: 'null',
        destinationCoordinates: place.geoCoordinates,
        locationPoints: _list,
        hasTapDestination: true,
        hasdestinationFromRecent: false,
        tappedPlace: FutureData<Place>.completed(place),
        businessAtAddress: 'null',
      ),
    );
    setDestinationMarker();

    // If it's an address (not a POI), search for businesses at that address
    if (place.placeType != PlaceType.poi && place.geoCoordinates != null) {
      _searchBusinessesAtAddress(place.geoCoordinates!);
    } else {
      // Clear businesses if it's already a POI
      emit(state.copyWith(businessAtAddress: 'null'));
    }
  }

  /// Set destination from a Place object (used for category search results)
  void setDestinationFromPlace(Place place) {
    if (state.currentPlace?.data == null) return;

    final destinationPoint = LocationPoint(
      place: place,
      pointType: LocationPointType.destination,
    );
    final List<LocationPoint> _list = [];
    _list.add(
      LocationPoint(
        place: state.currentPlace!.data!,
        isMyLocation: true,
        pointType: LocationPointType.starting,
      ),
    );
    _list.add(destinationPoint);

    emit(
      state.copyWith(
        destinationCoordinates: place.geoCoordinates,
        locationPoints: _list,
        hasTapDestination: true,
        businessAtAddress: 'null',

        tappedPlace: FutureData<Place>.completed(place),
      ),
    );
    setDestinationMarker();
  }

  void createTrip(List<LocationPoint> points) {
    final List<LocationPoint> _list = [];
    _list.addAll(points);

    emit(
      state.copyWith(
        destinationCoordinates: points[1].geoCoordinates,
        locationPoints: _list,
        hasTapDestination: true,
        // tappedPlace: FutureData<Place>.completed(points[1].place),
      ),
    );
    setDestinationMarker();
    calculateRoute();
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

  void calculateRouteWithBusinessOverview(Place? place) {
    if (place == null || place.geoCoordinates == null) return;
    final List<LocationPoint> points = [
      LocationPoint(
        place: state.currentPlace?.data,
        pointType: LocationPointType.starting,
        isMyLocation: true,
      ),
      LocationPoint(
        place: place,
        pointType: LocationPointType.destination,
        isMyLocation: false,
      ),
    ];
    createTrip(points);
  }

  void calculateRoute() {
    if ((state.locationPoints ?? []).isEmpty) return;
    GeoCoordinates? start = state.locationPoints?.firstOrNull?.geoCoordinates;
    GeoCoordinates? end = state.locationPoints?.lastOrNull?.geoCoordinates;

    if (start == null || end == null) return;

    // Update transport profile before calculating route to ensure restrictions are accurate
    _setupTransportProfile();

    final waypoints = List.generate(
      state.locationPoints!.length,
      (i) => Waypoint(state.locationPoints![i].geoCoordinates!),
    );

    final truckOptions = _createTruckOptions();

    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
      RoutingError? error,
      List<Route>? routes,
    ) {
      if (error != null || routes == null) return;

      final route = routes.first;
      _showRouteOnMap(route);
      refreshStopAndDestinationMarker();
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
          15.0,
        ),
        // AppColorTheme().cyan,
        material.Colors.blue,
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
    animateToRoute(route);
  }

  void animateToRoute([Route? route]) {
    final Route? _route = route ?? state.currentRoute;
    if (_route == null) return;
    Point2D origin = Point2D(80, 80);
    Size2D sizeInPixels = Size2D(
      state.mapController!.viewportSize.width - 250,
      state.mapController!.viewportSize.height - 250,
    );
    Rectangle2D mapViewport = Rectangle2D(origin, sizeInPixels);

    MapCameraUpdate cameraUpdate =
        MapCameraUpdateFactory.lookAtAreaWithGeoOrientationAndViewRectangle(
          _route.boundingBox,
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
        state.copyWith(
          isNavigating: true,
          nextTargetIndex: 1,
          cameraControlledByNavigator: true,
        ),
      );
      _simulator = HEREPositioningSimulator();

      final LocationListener navigatorForwarder = LocationListener((
        Location location,
      ) {
        _navigator?.onLocationUpdated(location);
        checkNextTarget(location.coordinates);
      });

      _simulator?.startLocating(
        _visualNavigator!,
        navigatorForwarder,
        state.currentRoute!,
      );
    } else {
      emit(
        state.copyWith(
          nextTargetIndex: 1,
          isNavigating: true,
          maneuverProgresses: [],
          cameraControlledByNavigator: true,
        ),
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
    emit(
      state.copyWith(cameraControlledByNavigator: false, nextTargetIndex: 1),
    );

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

    clearAllStopMarker();

    _clearTruckPreviousMarkers();

    emit(
      state.copyWith(
        destinationSuggestions: FutureData<List<Suggestion>>.initial(),
        selectedSuggestion: removeDestination ? 'null' : null,
        destinationCoordinates: removeDestination ? 'null' : null,
        currentRoute: 'null',
        hasDirection: false,
        tappedPlace: 'null',
        nextTargetIndex: 1,
        isNavigating: false,
        destinationFromRecent: 'null',
        businessAtAddress: 'null',
        hasdestinationFromRecent: false,
        locationPoints: [],
        maneuverProgresses: [],
        showBusinessOverviewModal: false,
        hasTapDestination: false,
      ),
    );
  }

  void setupManeuverUpdates() {
    if (_visualNavigator == null) return;
    _visualNavigator!.routeProgressListener = RouteProgressListener((
      RouteProgress progress,
    ) {
      emit(state.copyWith(maneuverProgresses: progress.maneuverProgress));
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

  void selectRecentAsDestination(RecentSearchModel recent) {
    if (recent.isBussiness) {
      _handleRecentBusinessPlaceForDestination(recent);
      return;
    }

    final GeoCoordinates geoCoordinates = GeoCoordinates(
      recent.latitude,
      recent.longitude,
    );

    final List<LocationPoint> _list = [];
    _list.add(
      LocationPoint(
        place: state.currentPlace!.data!,
        isMyLocation: true,
        pointType: LocationPointType.starting,
      ),
    );
    _list.add(
      LocationPoint(place: recent, pointType: LocationPointType.destination),
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
    if (!recent.isBussiness) {
      _searchBusinessesAtAddress(recent.geoCoordinates);
    }
    setDestinationMarker();
  }

  void setDestinationMarker({
    final hasFocus = true,
    bool hasDestinationConfirmed = false,
  }) async {
    final LocationPoint? destinationPoint = state.locationPoints?.lastOrNull;
    if (destinationPoint == null) return;
    // Add destination marker
    if (_destinationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_destinationMarker!);
      _destinationMarker = null;
    }

    MapImage? destIcon;

    if (hasDestinationConfirmed) {
      final units = await assetToFile(AppImages.redLocationIcon);
      if (units == null) return;

      destIcon = MapImage.withImageDataImageFormatWidthAndHeight(
        units,
        ImageFormat.png,
        80,
        110,
      );
    } else {
      destIcon = MapImage.withFilePathAndWidthAndHeight(
        AppImages.greenMapPin,
        60,
        100,
      );
    }

    _destinationMarker = MapMarker(destinationPoint.geoCoordinates!, destIcon);

    // 👇 THIS FIXES THE JUMPING & OFFSET
    _destinationMarker!.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.0);

    state.mapController?.mapScene.addMapMarker(_destinationMarker!);
    if (hasFocus) focusDestinationWithOffset(destinationPoint.geoCoordinates!);
  }

  Future<Uint8List?> assetToFile(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      return bytes;
    } catch (e) {
      return null;
    }
  }

  clearAllStopMarker() {
    if (_stopMarkers.isEmpty) return;
    for (var _sm in _stopMarkers.entries) {
      state.mapController?.mapScene.removeMapMarker(_sm.value);
    }
    _stopMarkers = {};
  }

  clearStopMarkerAt(i) {
    if (_stopMarkers.isEmpty) return;
    final _sm = _stopMarkers[i];
    if (_sm == null) return;
    state.mapController?.mapScene.removeMapMarker(_sm);
    _stopMarkers.remove(i);
  }

  Future<void> refreshStopAndDestinationMarker() async {
    clearAllStopMarker();
    for (var i = 0; i < (state.locationPoints ?? []).length; i++) {
      if (i == 0) continue;
      if (i == state.locationPoints!.length - 1) {
        setDestinationMarker(hasDestinationConfirmed: true);
        continue;
      }
      await addStopMakerAt(i, hasFocus: false);
    }
  }

  // MapMarker createRandomMapMarkerInViewport(
  //   HereMapController mapController,
  //   String label,
  // ) {
  //   GeoBox viewport = mapController.camera.boundingBox!;
  //   GeoCoordinates coordinates = GeoCoordinates(
  //     viewport.southWestCorner.latitude +
  //         (viewport.northEastCorner.latitude -
  //                 viewport.southWestCorner.latitude) *
  //             (DateTime.now().millisecondsSinceEpoch % 100) /
  //             100,
  //     viewport.southWestCorner.longitude +
  //         (viewport.northEastCorner.longitude -
  //                 viewport.southWestCorner.longitude) *
  //             (DateTime.now().millisecondsSinceEpoch % 100) /
  //             100,
  //   );

  //   MapImage image = MapImage.withImageAndText(
  //     label,
  //     const TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
  //   );

  //   return MapMarker(coordinates, image);
  // }

  Future<void> addStopMakerAt(int i, {bool hasFocus = true}) async {
    final GeoCoordinates? markerCoordinate =
        state.locationPoints?[i].geoCoordinates;
    if (markerCoordinate == null) return;
    final MapImage markerIcon = await _createStopMarkerImage(i);
    final marker = MapMarker(markerCoordinate, markerIcon);
    state.mapController?.mapScene.addMapMarker(marker);
    _stopMarkers[i] = marker;
    if (hasFocus) focusDestinationWithOffset(markerCoordinate);
  }

  editStopMarkerAt(i) {
    clearStopMarkerAt(i);
    addStopMakerAt(i);
  }

  void _handleMapTapForDestination(GeoCoordinates? geoCoordinates) {
    // Convert screen coordinates to geo coordinates
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

  void _handlePickedPlaceForDestination(PickedPlace pickedPlace) {
    try {
      // Emit loading state
      emit(
        state.copyWith(
          hasTapDestination: true,
          destinationCoordinates: pickedPlace.coordinates,
          tappedPlace: FutureData<Place>.loading(),
        ),
      );

      // Search by text using the POI name to get the actual POI place
      // This ensures we get the POI instead of an address
      final SearchOptions options = SearchOptions()
        ..languageCode = LanguageCode.enUs
        ..maxItems = 10; // Get more results to find the matching POI

      TextQueryArea queryArea = TextQueryArea.withCenter(
        pickedPlace.coordinates,
      );

      _searchEngine.suggestByText(
        TextQuery.withArea(pickedPlace.name, queryArea),
        options,
        (SearchError? error, List<Suggestion>? suggestions) {
          if (error != null) {
            log("Search by text failed: $error");
            // Fallback to reverse geocoding
            _reverseGeocodeDestination(pickedPlace.coordinates);
            return;
          }

          if (suggestions == null || suggestions.isEmpty) {
            // Fallback to reverse geocoding
            _reverseGeocodeDestination(pickedPlace.coordinates);
            return;
          }

          // Find the suggestion that matches the coordinates and has a place
          Place? foundPlace;
          for (final suggestion in suggestions) {
            if (suggestion.place != null) {
              final place = suggestion.place!;
              // Check if coordinates are available and close (within ~100m)
              if (place.geoCoordinates != null) {
                final distance = pickedPlace.coordinates.distanceTo(
                  place.geoCoordinates!,
                );
                if (distance < 100) {
                  // Also check if it's a POI (not an address)
                  if (place.placeType == PlaceType.poi) {
                    foundPlace = place;
                    break;
                  }
                }
              }
            }
          }

          // If we found a matching POI, use it; otherwise fallback to reverse geocoding
          if (foundPlace != null) {
            if (foundPlace.isBusiness) {
              searchBusinessDetailsByPlaceId(
                foundPlace.id,
                (p) => onPickedPlaceFound(p),
                (error) => onPickedPlaceFound(foundPlace),
              );
            } else {
              onPickedPlaceFound(foundPlace);
            }
          } else {
            // Fallback to reverse geocoding if no matching POI found
            _reverseGeocodeDestination(pickedPlace.coordinates);
          }
        },
      );
    } catch (e) {
      log(e.toString());
    }
  }

  void onPickedPlaceFound(Place? foundPlace) {
    if (foundPlace == null) return;
    final List<LocationPoint> _list = [];
    if (state.currentPlace?.data != null) {
      _list.add(
        LocationPoint(
          place: state.currentPlace!.data!,
          isMyLocation: true,
          pointType: LocationPointType.starting,
        ),
      );
    }
    _list.add(
      LocationPoint(
        place: foundPlace,
        pointType: LocationPointType.destination,
      ),
    );
    emit(
      state.copyWith(
        locationPoints: _list,
        tappedPlace: FutureData.completed(foundPlace),
      ),
    );
    setDestinationMarker();
  }

  void _handleRecentBusinessPlaceForDestination(RecentSearchModel recent) {
    // Emit loading state
    emit(
      state.copyWith(
        hasTapDestination: true,
        destinationCoordinates: recent.geoCoordinates,
        tappedPlace: FutureData<Place>.loading(),
      ),
    );

    // Search by text using the POI name to get the actual POI place
    // This ensures we get the POI instead of an address
    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 10; // Get more results to find the matching POI

    TextQueryArea queryArea = TextQueryArea.withCenter(recent.geoCoordinates);

    _searchEngine.suggestByText(
      TextQuery.withArea(recent.title, queryArea),
      options,
      (SearchError? error, List<Suggestion>? suggestions) {
        if (error != null) {
          log("Search by text failed: $error");
          // Fallback to reverse geocoding
          _reverseGeocodeDestination(recent.geoCoordinates);
          return;
        }

        if (suggestions == null || suggestions.isEmpty) {
          // Fallback to reverse geocoding
          _reverseGeocodeDestination(recent.geoCoordinates);
          return;
        }

        // Find the suggestion that matches the coordinates and has a place
        Place? foundPlace;
        for (final suggestion in suggestions) {
          if (suggestion.place != null) {
            final place = suggestion.place!;
            // Check if coordinates are available and close (within ~100m)
            if (place.geoCoordinates != null) {
              final distance = recent.geoCoordinates.distanceTo(
                place.geoCoordinates!,
              );
              if (distance < 100) {
                // Also check if it's a POI (not an address)
                if (place.placeType == PlaceType.poi) {
                  foundPlace = place;
                  break;
                }
              }
            }
          }
        }

        // If we found a matching POI, use it; otherwise fallback to reverse geocoding
        if (foundPlace != null) {
          if (foundPlace.isBusiness) {
            searchBusinessDetailsByPlaceId(
              foundPlace.id,
              (p) => onPickedPlaceFound(p),
              (error) => onPickedPlaceFound(foundPlace),
            );
          } else {
            onPickedPlaceFound(foundPlace);
          }
        } else {
          // Fallback to reverse geocoding if no matching POI found
          _reverseGeocodeDestination(recent.geoCoordinates);
        }
      },
    );
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

        if (places.firstOrNull?.isBusiness == false &&
            places.firstOrNull?.geoCoordinates != null) {
          _searchBusinessesAtAddress(places.first.geoCoordinates!);
        }
        if (state.currentPlace?.data != null) {
          _list.add(
            LocationPoint(
              place: state.currentPlace!.data!,
              isMyLocation: true,
              pointType: LocationPointType.starting,
            ),
          );
        }
        _list.add(
          LocationPoint(
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
        businessAtAddress: 'null',
      ),
    );
  }

  Future<void> changeLocationPointOrder(oldIndex, newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    if (_list.isEmpty) return;
    final removed = _list.removeAt(oldIndex);
    _list.insert(newIndex, removed);
    emit(state.copyWith(locationPoints: _list));
    calculateRoute();
    // await refreshStopAndDestinationMarker();
  }

  void addStop(dynamic place) {
    if (place == null) return;
    final isRecent = place is RecentSearchModel;
    if ((state.locationPoints ?? []).isEmpty) return;
    late bool any;
    if (isRecent) {
      any =
          state.locationPoints?.any(
            (e) =>
                e.geoCoordinates?.latitude == place.geoCoordinates.latitude &&
                e.geoCoordinates?.longitude == place.geoCoordinates.longitude,
          ) ??
          true;
    } else {
      any =
          state.locationPoints?.any(
            (e) =>
                e.geoCoordinates?.latitude ==
                    (place as Place).geoCoordinates?.latitude &&
                e.geoCoordinates?.longitude == place.geoCoordinates?.longitude,
          ) ??
          true;
    }
    if (any) return;

    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    final item = LocationPoint(place: place, pointType: LocationPointType.stop);
    // final addIndex = state.locationPoints!.length - 1;
    final addIndex = state.locationPoints!.length;
    _list.insert(addIndex, item);
    emit(state.copyWith(locationPoints: _list));
    // addStopMakerAt(addIndex);
    // refreshStopAndDestinationMarker();
    calculateRoute();
  }

  void editStop(int i, dynamic place) {
    if (place == null) return;
    if ((state.locationPoints ?? []).isEmpty) return;
    // if (i == 0) return;
    // if (i >= (state.locationPoints?.length ?? 0) - 1) return;
    final isDestination = i == (state.locationPoints?.length ?? 0) - 1;
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    _list[i] = _list[i].copyWith(place: place);
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: isDestination ? _list[i].geoCoordinates : null,
      ),
    );
    calculateRoute();
    if (i == 0) return;
    if (isDestination) {
      setDestinationMarker();
    } else {
      editStopMarkerAt(i);
    }
  }

  void deleteStop(int index) {
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    if (_list.isEmpty) return;
    if (_list.length <= 2) return;
    // if (index == 0) return;
    // if (index >= (state.locationPoints?.length ?? 0) - 1) return;
    _list.removeAt(index);
    emit(state.copyWith(locationPoints: _list));
    clearStopMarkerAt(index);
    calculateRoute();
  }

  void searchBusinessDetailsByPlaceId(
    placeId,
    Function(Place? place) onSuccess,
    Function(String? error) onError,
  ) {
    _searchEngine.searchByPlaceId(PlaceIdQuery(placeId), LanguageCode.enUs, (
      error,
      place,
    ) {
      if (error != null) onError(error.name);
      onSuccess(place);
    });
  }

  /// Search for businesses at a specific address/coordinates
  void _searchBusinessesAtAddress(GeoCoordinates coordinates) {
    final SearchOptions searchOptions = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 10;

    _searchEngine.searchByCoordinates(coordinates, searchOptions, (
      SearchError? error,
      List<Place>? places,
    ) {
      final int bussinessIndex = places?.indexWhere((p) => p.isBusiness) ?? -1;
      if (bussinessIndex != -1) {
        emit(state.copyWith(businessAtAddress: places?[bussinessIndex]));
      }
    });
  }
}
