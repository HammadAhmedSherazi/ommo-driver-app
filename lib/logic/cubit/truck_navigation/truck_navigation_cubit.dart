import 'dart:async';
import 'dart:developer';
import 'dart:math' as m;
import 'dart:ui' as ui;

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
import 'package:ommo/logic/cubit/route_truck_specs/route_truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stop_cubit.dart';
import 'package:ommo/map_sdk/HEREPositioningSimulator.dart';
import 'package:ommo/models/location_point_model.dart';
import 'package:ommo/models/models.dart';
import 'package:ommo/services/hive/places_cache/places_cache_service.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/helpers/wake_lock_utils.dart';
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
  MapMarker? _startMarker;
  Map<int, MapMarker> _stopMarkers = {};
  List<MapMarker> _truckRestrictionMarkers = [];
  final loc.Location _location = loc.Location();
  bool isFirstTimeLocationGet = true;
  MapCameraListener? _mapCameraListener;
  Timer? _mapInteractionDebounceTimer;

  /// Lateral distance from route polyline before treating as off-route.
  /// Must be well above typical GPS error (often 5–15 m) and lane offset from centerline.
  static const double _offRouteThresholdMeters = 50.0;

  /// Minimum movement before updating the map “my location” marker when not navigating.
  static const double _myLocationOffThresholdMeters = 50.0;
  static const int _offRouteConfirmationCount =
      3; // Consecutive off-route samples before triggering recalculation
  static const int _recalculationCooldownSeconds =
      25; // Minimum seconds between recalculations
  static const int _maxRouteOrNavigationRetries = 3;
  int _offRouteConsecutiveCount = 0;
  DateTime? _lastRecalculationTime;

  bool firstLocationReceived = false;
  Future<MapImage> _createStopMarkerImage(
    int? index, [
    double size = 70.0,
  ]) async {
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

    if (index != null) {
      paragraphBuilder.pushStyle(ui.TextStyle(color: ui.Color(0xFF000000)));
      paragraphBuilder.addText('$index');
    }

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

  // this is unnesseccary because of this isMapLoading
  // Setters
  // void setInitialLocation(GeoCoordinates coords) {
  //   emit(state.copyWith(isMapLoading: false, startCoordinates: coords));
  //   _updateCurrentLocationMarker();
  // }
  // this is unnesseccary because of this isMapLoading

  void setCurrentLocation(GeoCoordinates coords, [String? source]) {
    log("setCurrentLocation: $source with coords: $coords");
    emit(state.copyWith(startCoordinates: coords));
    _updateCurrentLocationMarker();
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

      // Setup camera listener to detect manual map interactions
      _setupMapInteractionListener(controller);

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
          // Handle custom markers (truck restriction warnings, stop markers, destination)
          if ((result.mapItems?.markers ?? []).isNotEmpty) {
            final MapMarker? pickedMarker =
                result.mapItems?.markers.firstOrNull;

            if (pickedMarker != null) {
              // Handle truck restriction warnings
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
          // Handle stop markers and destination marker when not navigating

          final PickedPlace? pickedPlace =
              result.mapContent?.pickedPlaces.firstOrNull;
          if (pickedPlace != null) {
            _handlePickedPlaceForDestination(pickedPlace);
          }

          if ((result.mapItems?.markers ?? []).isNotEmpty) {
            final MapMarker? pickedMarker =
                result.mapItems?.markers.firstOrNull;

            if (pickedMarker != null) {
              // Check for place markers (truck stops)
              final String? placeId = pickedMarker.metadata?.getString(
                "place_id",
              );
              if (placeId != null) {
                final Map<String, Place> placeDataMap =
                    navigatorKey.currentContext
                        ?.read<TruckStopCubit>()
                        .placeDataMap ??
                    {};
                if (placeDataMap.isNotEmpty &&
                    placeDataMap.containsKey(placeId)) {
                  final Place place = placeDataMap[placeId]!;
                  navigatorKey.currentContext
                      ?.read<TruckStopCubit>()
                      .showBusinessOverviewModal(place);
                  return;
                }
              }
            }
          }
        } else if (state.hasDirection && !state.isNavigating) {
          // Handle stop markers and destination marker when route is shown but not navigating
          if ((result.mapItems?.markers ?? []).isNotEmpty) {
            final MapMarker? pickedMarker =
                result.mapItems?.markers.firstOrNull;
            if (pickedMarker != null) {
              final String? markerType = pickedMarker.metadata?.getString(
                "marker_type",
              );

              // Check for stop marker
              if (markerType == "start") {
                if ((state.locationPoints ?? []).isNotEmpty) {
                  final GeoCoordinates? coords =
                      state.locationPoints?.firstOrNull?.geoCoordinates;
                  if (coords != null) {
                    focusOnStopOrDestination(coords);
                    return;
                  }
                }
              }

              if (markerType == "stop") {
                final String? stopIndexStr = pickedMarker.metadata?.getString(
                  "stop_index",
                );
                if (stopIndexStr != null) {
                  final int? stopIndex = int.tryParse(stopIndexStr);
                  if (stopIndex != null &&
                      state.locationPoints != null &&
                      stopIndex < state.locationPoints!.length) {
                    final GeoCoordinates? coords =
                        state.locationPoints![stopIndex].geoCoordinates;
                    if (coords != null) {
                      focusOnStopOrDestination(coords);
                      return;
                    }
                  }
                }
              }

              // Check for destination marker
              if (markerType == "destination") {
                final GeoCoordinates? coords = state.destinationCoordinates;
                if (coords != null) {
                  focusOnStopOrDestination(coords);
                  return;
                }
              }
            }
          }

          // Handle regular place picks (only if no marker was handled)
          if (!state.isNavigating && !state.hasDirection) {
            final PickedPlace? pickedPlace =
                result.mapContent?.pickedPlaces.firstOrNull;
            if (pickedPlace != null) {
              _handlePickedPlaceForDestination(pickedPlace);
            }
          }
        }
      });
    });

    if (state.startCoordinates != null) {
      setCurrentLocation(state.startCoordinates!, "onMapCreated");
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
    // Start location as soon as map is ready so HERE engine has time to get first fix
    // (no delay — previously 4s delay in map_view caused slow first location)
    startListeningToLocation();
  }

  /// Setup camera listener to detect when user manually moves the map
  void _setupMapInteractionListener(HereMapController controller) {
    // Remove existing listener if any
    if (_mapCameraListener != null) {
      controller.camera.removeListener(_mapCameraListener!);
    }

    // Create new listener to detect manual map movements
    _mapCameraListener = MapCameraListener((MapCameraState mapState) {
      // User is interacting with the map
      if (!state.isUserInteractingWithMap) {
        emit(state.copyWith(isUserInteractingWithMap: true));
      }

      // Debounce: reset flag after user stops moving map for 1 second
      _mapInteractionDebounceTimer?.cancel();
      _mapInteractionDebounceTimer = Timer(const Duration(seconds: 1), () {
        if (state.isUserInteractingWithMap) {
          emit(state.copyWith(isUserInteractingWithMap: false));
        }
      });
    });

    // Add listener to camera
    controller.camera.addListener(_mapCameraListener!);
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

  /// Returns the shortest distance in meters from [point] to the route polyline.
  /// Used for off-route detection (Google Maps–style).
  double _getDistanceFromPointToRoute(GeoCoordinates point, Route route) {
    final List<GeoCoordinates> vertices = route.geometry.vertices;
    if (vertices.isEmpty) return double.infinity;
    if (vertices.length == 1) {
      return calculateDistanceInMeters(
        point.latitude,
        point.longitude,
        vertices.first.latitude,
        vertices.first.longitude,
      );
    }
    double minDistance = double.infinity;
    for (int i = 0; i < vertices.length - 1; i++) {
      final double d = _getDistanceFromPointToSegment(
        point,
        vertices[i],
        vertices[i + 1],
      );
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  /// Distance from point [p] to line segment [a]-[b] in meters.
  /// Uses projection onto segment and Haversine for the final distance.
  double _getDistanceFromPointToSegment(
    GeoCoordinates p,
    GeoCoordinates a,
    GeoCoordinates b,
  ) {
    final double ax = a.latitude;
    final double ay = a.longitude;
    final double bx = b.latitude;
    final double by = b.longitude;
    final double px = p.latitude;
    final double py = p.longitude;
    final double dx = bx - ax;
    final double dy = by - ay;
    final double lenSq = dx * dx + dy * dy;
    double t = 0.0;
    if (lenSq > 1e-20) {
      t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
      t = t.clamp(0.0, 1.0);
    }
    final double qx = ax + t * dx;
    final double qy = ay + t * dy;
    return calculateDistanceInMeters(px, py, qx, qy);
  }

  /// Checks if the user is off-route and triggers recalculation when appropriate.
  /// Uses consecutive off-route samples and a cooldown to avoid false positives and API spam.
  void _checkOffRouteAndRecalculateIfNeeded(GeoCoordinates coords) {
    if (!state.isNavigating ||
        state.currentRoute == null ||
        state.isNavigationCompleted) {
      _offRouteConsecutiveCount = 0;
      return;
    }

    if (state.isRecalculatingRoute) {
      return;
    }

    final double distanceToRoute = _getDistanceFromPointToRoute(
      coords,
      state.currentRoute!,
    );

    final bool inRecalculationCooldown =
        _lastRecalculationTime != null &&
        DateTime.now().difference(_lastRecalculationTime!).inSeconds <
            _recalculationCooldownSeconds;

    if (distanceToRoute > _offRouteThresholdMeters) {
      if (!state.isOffRoute) {
        emit(state.copyWith(isOffRoute: true));
      }
      // During cooldown, do not accumulate toward another reroute (avoids a burst right after reroute).
      if (inRecalculationCooldown) {
        return;
      }
      _offRouteConsecutiveCount++;
      if (_offRouteConsecutiveCount >= _offRouteConfirmationCount) {
        _offRouteConsecutiveCount = 0;
        _recalculateRouteFromCurrentPosition(coords);
      }
    } else {
      _offRouteConsecutiveCount = 0;
      if (state.isOffRoute) {
        emit(state.copyWith(isOffRoute: false));
      }
    }
  }

  /// Recalculates the route from the current position to the destination (and remaining waypoints).
  /// Preserves remaining stops so multi-stop trips are not lost.
  void _recalculateRouteFromCurrentPosition(GeoCoordinates currentPosition) {
    final points = state.locationPoints;
    if (points == null || points.length < 2) return;
    final int nextIndex = state.nextTargetIndex.clamp(0, points.length - 1);
    final List<Waypoint> waypoints = [
      Waypoint(currentPosition),
      ...List.generate(
        points.length - nextIndex,
        (i) => Waypoint(points[nextIndex + i].geoCoordinates!),
      ),
    ];
    if (waypoints.length < 2) return;

    emit(state.copyWith(isRecalculatingRoute: true));
    _setupTransportProfile();
    final truckOptions = _createTruckOptions();
    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
      RoutingError? error,
      List<Route>? routes,
    ) {
      emit(state.copyWith(isRecalculatingRoute: false));
      if (error != null || routes == null || routes.isEmpty) {
        // Apply cooldown on failure too, otherwise GPS ticks immediately re-trigger reroutes.
        _lastRecalculationTime = DateTime.now();
        emit(state.copyWith(isOffRoute: true));
        if (navigatorKey.currentContext != null) {
          SnackbarUtils.showErrorSnackBar(
            navigatorKey.currentContext!,
            'Could not find a new route. Stay on the current route.',
          );
        }
        return;
      }
      final Route newRoute = routes.first;
      _lastRecalculationTime = DateTime.now();
      emit(
        state.copyWith(
          currentRoute: newRoute,
          isOffRoute: false,
          maneuverProgresses: [],
          remainingDistanceInMeters: 'null',
          remainingDuration: 'null',
        ),
      );
      _visualNavigator?.route = newRoute;
      _showRouteOnMap(newRoute);
      _processTruckRestrictionWarnings(newRoute);
      if (navigatorKey.currentContext != null) {
        SnackbarUtils.showSuccessSnackBar(
          navigatorKey.currentContext!,
          'Route recalculated.',
        );
      }
    });
  }

  double _degreesToRadians(double degree) => degree * m.pi / 180.0;

  /// Check if map is in idle state (not navigating, searching, or creating trip)
  bool _isMapInIdleState() {
    // Not navigating
    if (state.isNavigating) return false;

    // User is manually interacting with the map (panning/zooming)
    if (state.isUserInteractingWithMap) return false;

    // No target destination or route
    if (state.hasTapDestination || state.hasDirection) return false;

    // Not creating trip (only starting point, no route)
    if ((state.locationPoints ?? []).length > 1) return false;

    // Not searching destination/place
    if (state.destinationSuggestions?.status == Status.loading) return false;

    // Not searching truck stops or viewing stop details
    try {
      final truckStopCubit = navigatorKey.currentContext
          ?.read<TruckStopCubit>();
      if (truckStopCubit != null) {
        final truckStopState = truckStopCubit.state;
        // Check if searching truck stops (has search results)
        if (truckStopState.currentPlaceType != null) {
          return false;
        }
      }
    } catch (e) {
      // If context is not available, assume not idle to be safe
      log("Error checking truck stop state: $e");
      return false;
    }

    // Camera not controlled by navigator (redundant check but included for safety)
    if (state.cameraControlledByNavigator) return false;

    return true;
  }

  void _updateCurrentLocationMarker() {
    if (state.isNavigating) {
      _clearCurrentLocationMarker();
      _clearStartMarker();
      return;
    }
    if (state.hasDirection && state.currentRoute != null) {
      addStartMaker();

      if (state.locationPoints?.any((p) => p.isMyLocation) == true) {
        return;
      }
    }
    final coords = state.startCoordinates;
    if (coords == null) return;
    _clearCurrentLocationMarker();
    MapImage userImage = MapImage.withFilePathAndWidthAndHeight(
      AppIcons.myLocIcon,
      60,
      60,
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

    // Focus on location first time or when map is in idle state
    if (isFirstTimeLocationGet) {
      isFirstTimeLocationGet = false;
      focusOnCurrentLocation();
    } else if (_isMapInIdleState()) {
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

    // Temporarily remove camera listener to avoid detecting programmatic movement as user interaction
    if (_mapCameraListener != null) {
      controller.camera.removeListener(_mapCameraListener!);
    }

    final mapMeasure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      distanceInMeters,
    );

    controller.camera.lookAtPointWithGeoOrientationAndMeasure(
      coords,
      GeoOrientationUpdate(0, 0),
      mapMeasure,
    );

    // Re-add listener after a short delay to allow camera animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_mapCameraListener != null) {
        controller.camera.addListener(_mapCameraListener!);
      }
    });
  }

  Future<void> ensureLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    var permission = await _location.hasPermission();

    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }
  }

  Future<void> _setInitialLocationFast() async {
    /// 1️⃣ Try HERE last known location
    final hereLocation = _locationEngine?.lastKnownLocation;

    if (hereLocation != null) {
      final age = DateTime.now().difference(hereLocation.time!);

      if (age.inMinutes < 5) {
        setCurrentLocation(hereLocation.coordinates, "HERE lastKnownLocation");
        return;
      }
    }

    /// 2️⃣ Fallback → Platform location (VERY FAST)
    try {
      final locData = await _location.getLocation();

      if (locData.latitude != null && locData.longitude != null) {
        setCurrentLocation(
          GeoCoordinates(locData.latitude!, locData.longitude!),
          "platform fallback",
        );
      }
    } catch (e) {
      print("Platform location failed: $e");
    }
  }

  // getLastKnownLocation() async {
  //   final location = _locationEngine?.lastKnownLocation;
  //   if (location == null) return;

  //   final age = DateTime.now().difference(location.time!);

  //   // Only use if location is recent
  //   if (age.inSeconds < 30) {
  //     setCurrentLocation(location.coordinates, "lastKnownLocation");
  //   }
  // }

  void startListeningToLocation() async {
    try {
      if (AppKeys().isSimulation) {
        setCurrentLocation(AppKeys().startCoordinates, "simulation");
        return;
      }

      if (_locationEngine != null) return;

      _locationEngine = LocationEngine();
      _locationEngine?.confirmHEREPrivacyNoticeInclusion();

      /// ✅ 1. Ensure permission (NON-BLOCKING)
      ensureLocationPermission();

      /// ✅ 2. Get instant fallback location (VERY IMPORTANT)
      _setInitialLocationFast();

      /// ✅ 3. Add listener immediately
      _locationEngine?.addLocationListener(
        LocationListener((Location location) {
          final coords = location.coordinates;
          final accuracy = location.horizontalAccuracyInMeters ?? 999;

          print("Location received: $coords | accuracy: $accuracy");

          /// ✅ ALWAYS accept first fix
          if (state.startCoordinates == null) {
            setCurrentLocation(coords, "HERE first fix");
            firstLocationReceived = true;
            return;
          }

          /// ✅ Apply accuracy filter AFTER first fix
          if (accuracy >= 30) return;

          if (!state.isNavigating) {
            final current = state.startCoordinates;

            if (current != null) {
              final distance = calculateDistanceInMeters(
                current.latitude,
                current.longitude,
                coords.latitude,
                coords.longitude,
              );

              if (distance > _myLocationOffThresholdMeters) {
                setCurrentLocation(coords, "distance update");
              }
            } else {
              setCurrentLocation(coords, "initial update");
            }
          }

          if (state.isNavigating) {
            setCurrentLocation(coords, "navigation update");

            emit(state.copyWith(currentNavigationLocation: coords));

            _visualNavigator?.onLocationUpdated(location);
            _navigator?.onLocationUpdated(location);

            checkNextTarget(coords);
            _checkOffRouteAndRecalculateIfNeeded(coords);
          }
        }),
      );

      /// ✅ 4. Start HERE engine immediately (NO DELAY)
      _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);

      /// ✅ 5. Optional: soft fallback check (no aggressive restart)
      Future.delayed(const Duration(seconds: 12), () {
        if (!firstLocationReceived) {
          print("Still waiting for GPS fix...");
          // ❌ DO NOT restart immediately (prevents TTFF reset)
        }
      });
    } catch (e) {
      print("Error starting location: $e");
    }
  }
  // void startListeningToLocation() async {
  //   try {
  //     if (AppKeys().isSimulation) {
  //       setCurrentLocation(
  //         AppKeys().startCoordinates,
  //         "startListeningToLocation",
  //       );
  //     } else {
  //       if (_locationEngine != null) return;

  //       _locationEngine = LocationEngine();
  //       _locationEngine?.confirmHEREPrivacyNoticeInclusion();

  //       // Warm up device location (important for some Android devices)
  //       await _getCurrentLocation();

  //       getLastKnownLocation();

  //       _locationEngine?.addLocationListener(
  //         LocationListener((Location location) {
  //           final GeoCoordinates coords = location.coordinates;
  //           final accuracy = location.horizontalAccuracyInMeters ?? 999;

  //           print("Location received: $coords | accuracy: $accuracy");

  //           /// ✅ 1. ALWAYS accept first fix (CRITICAL FIX)
  //           if (state.startCoordinates == null) {
  //             setCurrentLocation(coords, "HERE first fix (no accuracy filter)");
  //             firstLocationReceived = true;
  //             return;
  //           }

  //           /// ✅ 2. After first fix → apply accuracy filter
  //           if (accuracy >= 30) return;

  //           // if (location.horizontalAccuracyInMeters == null ||
  //           //     location.horizontalAccuracyInMeters! >= 50) {
  //           //   return;
  //           // }

  //           // final GeoCoordinates coords = location.coordinates;
  //           // log("Location recieved $coords");

  //           if (!state.isNavigating) {
  //             if (state.startCoordinates != null) {
  //               final double distance = calculateDistanceInMeters(
  //                 state.startCoordinates!.latitude,
  //                 state.startCoordinates!.longitude,
  //                 coords.latitude,
  //                 coords.longitude,
  //               );

  //               print(
  //                 "has Distance of $distance > $_myLocationOffThresholdMeters ${distance > _myLocationOffThresholdMeters}",
  //               );

  //               if (distance > _myLocationOffThresholdMeters) {
  //                 setCurrentLocation(
  //                   coords,
  //                   "location engine update with distance",
  //                 );
  //                 return;
  //               }
  //             } else {
  //               setCurrentLocation(
  //                 coords,
  //                 "location engine initial coordinates",
  //               );
  //             }
  //           }

  //           if (state.isNavigating) {
  //             setCurrentLocation(
  //               coords,
  //               "location engine update in navigation",
  //             );

  //             emit(state.copyWith(currentNavigationLocation: coords));

  //             _visualNavigator?.onLocationUpdated(location);
  //             _navigator?.onLocationUpdated(location);

  //             checkNextTarget(coords);
  //             _checkOffRouteAndRecalculateIfNeeded(coords);
  //           }
  //         }),
  //       );

  //       // Start HERE location engine
  //       _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);

  //       // Fallback restart (fixes cold start issue on Vivo / Oppo)
  //       Future.delayed(const Duration(seconds: 8), () {
  //         if (!firstLocationReceived && _locationEngine != null) {
  //           // print("Restarting location engine due to no GPS fix");

  //           _locationEngine?.stop();
  //           _locationEngine = null;
  //           startListeningToLocation();
  //           // _locationEngine?.startWithLocationAccuracy(
  //           //   LocationAccuracy.navigation,
  //           // );
  //         }
  //       });
  //     }
  //   } on Exception catch (e) {
  //     // TODO
  //     print("Got an error from start location listening $e");

  //     if (!firstLocationReceived && _locationEngine != null) {
  //       // print("Restarting location engine due to no GPS fix");

  //       _locationEngine?.stop();
  //       _locationEngine = null;
  //       startListeningToLocation();
  //       // _locationEngine?.startWithLocationAccuracy(
  //       //   LocationAccuracy.navigation,
  //       // );
  //     }
  //   }
  // }

  // void startListeningToLocation() async {
  //   if (AppKeys().isSimulation) {
  //     setCurrentLocation(
  //       AppKeys().startCoordinates,
  //       "startListeningToLocation",
  //     );
  //   } else {
  //     if (_locationEngine != null) return; // Already started, avoid double init
  //     _locationEngine = LocationEngine();
  //     _locationEngine?.confirmHEREPrivacyNoticeInclusion();
  //     // Ensure permission is granted before starting HERE engine (so first fix can be delivered).
  //     // Do NOT use this result for setCurrentLocation — different source than LocationEngine
  //     // would cause map to "jump" when engine's first update arrives.
  //     await _getCurrentLocation();

  //     _locationEngine?.addLocationListener(
  //       LocationListener((Location location) {

  //         // Only use location if accuracy is good
  //         if (location.horizontalAccuracyInMeters == null ||
  //             location.horizontalAccuracyInMeters! >= 50) {
  //           return;
  //         }

  //         final GeoCoordinates coords = location.coordinates;
  //         log("Location recieved $coords");

  //         if (!state.isNavigating) {
  //           if (state.startCoordinates != null) {
  //             final double distance = calculateDistanceInMeters(
  //               state.startCoordinates!.latitude,
  //               state.startCoordinates!.longitude,
  //               coords.latitude,
  //               coords.longitude,
  //             );
  //             print("has Distance of $distance > 10 ${distance > 10}");
  //             if (distance > 10) {
  //               setCurrentLocation(
  //                 coords,
  //                 "location engine update with distance",
  //               );
  //               return;
  //             }
  //           } else {
  //             setCurrentLocation(coords, "location engine initial coordinates");
  //           }
  //         }
  //         if (state.isNavigating) {
  //           setCurrentLocation(coords, "location engine update in navigation");
  //           // Update currentNavigationLocation with raw GPS location for accurate distance calculations
  //           emit(state.copyWith(currentNavigationLocation: coords));
  //           _visualNavigator?.onLocationUpdated(location);
  //           _navigator?.onLocationUpdated(location);
  //           checkNextTarget(coords);
  //           _checkOffRouteAndRecalculateIfNeeded(coords);
  //          }
  //       }),
  //     );

  //     _locationEngine?.startWithLocationAccuracy(
  //       LocationAccuracy.navigation,
  //     );
  //   }
  // }

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

  Future<void> getCurrentLocationPlace({
    void Function(PlaceDataModel? place)? onComplete,
  }) async {
    if (state.startCoordinates == null) {
      emit(
        state.copyWith(
          currentPlace: FutureData.error(
            "Unable to retrieve details because the current location could not be determined.",
          ),
        ),
      );
      onComplete?.call(null);
      return;
    }

    final GeoCoordinates currentCoords = state.startCoordinates!;
    final cached = PlacesHiveCacheService.instance.getReverseGeocodedPlace(
      currentCoords,
    );
    if (cached != null) {
      emit(state.copyWith(currentPlace: FutureData.completed(cached)));
      onComplete?.call(cached);
      return;
    }

    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    _searchEngine.searchByCoordinates(currentCoords, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        log("Reverse geocoding failed: $error");
        onComplete?.call(null);
        return;
      }
      if (places != null && places.isNotEmpty) {
        final placeDataModel = places.firstOrNull?.toPlaceDataModel;

        if (placeDataModel != null) {
          unawaited(
            PlacesHiveCacheService.instance.putReverseGeocodedPlace(
              currentCoords,
              placeDataModel,
            ),
          );
          emit(
            state.copyWith(currentPlace: FutureData.completed(placeDataModel)),
          );
          onComplete?.call(placeDataModel);
        } else {
          emit(
            state.copyWith(
              currentPlace: FutureData.error(
                "No details available of current location",
              ),
            ),
          );
          onComplete?.call(null);
        }
      } else {
        emit(
          state.copyWith(
            currentPlace: FutureData.error(
              "No details available of current location",
            ),
          ),
        );
        onComplete?.call(null);
      }
    });
  }

  /// Re-resolve current GPS to a [Place] and apply it to a stop (e.g. user taps "My location" again).
  void refreshStopWithCurrentLocation(
    int index, {
    void Function()? onComplete,
  }) {
    if ((state.locationPoints ?? []).isEmpty) {
      onComplete?.call();
      return;
    }
    if (index < 0 || index >= state.locationPoints!.length) {
      onComplete?.call();
      return;
    }
    getCurrentLocationPlace(
      onComplete: (place) {
        if (place != null) {
          editStop(index, place, isMyLocation: true);
        }
        onComplete?.call();
      },
    );
  }

  /// Add a stop at the current GPS position using a fresh reverse-geocode.
  void addStopWithCurrentLocation({void Function()? onComplete}) {
    getCurrentLocationPlace(
      onComplete: (place) {
        if (place != null) {
          addStop(place, isMyLocation: true);
        }
        onComplete?.call();
      },
    );
  }

  /// Routing and Navigation Functions
  void searchPlaces(String query) {
    if (query == '') {
      emit(state.copyWith(destinationSuggestions: FutureData.completed([])));
      return;
    }

    if (state.startCoordinates == null) return;
    final coords = state.startCoordinates!;
    final cached = PlacesHiveCacheService.instance.getTextSearchPlaces(
      query,
      coords,
    );
    if (cached != null && cached.isNotEmpty) {
      emit(
        state.copyWith(destinationSuggestions: FutureData.completed(cached)),
      );
      return;
    }

    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 5;

    TextQueryArea queryArea = TextQueryArea.withCenter(coords);

    _searchEngine.suggestByText(
      TextQuery.withArea(query, queryArea),
      searchOptions,
      (SearchError? searchError, List<Suggestion>? list) {
        for (Suggestion element in list ?? []) {
          log("element: ${element.place?.id}");
          log("element: ${element.place?.title}");
          log("element: ${element.place?.address.addressText}");
        }
        final filteredList = list
            ?.where((element) => element.place?.id != null)
            .map((e) => e.place!.toPlaceDataModel)
            .toList();

        if (filteredList != null && filteredList.isNotEmpty) {
          unawaited(
            PlacesHiveCacheService.instance.putTextSearchPlaces(
              query,
              coords,
              filteredList,
            ),
          );
        }
        if (filteredList != null) {
          emit(
            state.copyWith(
              destinationSuggestions: FutureData.completed(filteredList),
            ),
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

  void selectSuggestionAsDestination(PlaceDataModel? place) {
    // final place = suggestion.place;
    if (place == null) return;
    selectBusinessSuggestionAsDestination(place);
  }

  void selectBusinessSuggestionAsDestination(PlaceDataModel place) {
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

  void setDestination(PlaceDataModel? place) {
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
        tappedPlace: FutureData<PlaceDataModel>.completed(place),
        businessAtAddress: 'null',
      ),
    );
    setDestinationMarker();

    // If it's an address (not a POI), search for businesses at that address
    if (!place.isBusiness) {
      _searchBusinessesAtAddress(place.geoCoordinates!);
    } else {
      // Clear businesses if it's already a POI
      emit(state.copyWith(businessAtAddress: 'null'));
    }
  }

  /// Set destination from a Place object (used for category search results)
  void setDestinationFromPlace(PlaceDataModel place) {
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
        tappedPlace: FutureData<PlaceDataModel>.completed(place),
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
    calculateRoute(isRecalculating: false);
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

  /// Focus on a stop or destination marker with close zoom for detailed view
  void focusOnStopOrDestination(GeoCoordinates coords) {
    if (state.mapController == null) return;

    // Temporarily remove camera listener to avoid detecting programmatic movement as user interaction
    if (_mapCameraListener != null) {
      state.mapController!.camera.removeListener(_mapCameraListener!);
    }

    // Close zoom distance for detailed view (500 meters)
    const double zoomDistance = 500;
    final mapMeasure = MapMeasure(
      MapMeasureKind.distanceInMeters,
      zoomDistance,
    );

    state.mapController!.camera.lookAtPointWithGeoOrientationAndMeasure(
      coords,
      GeoOrientationUpdate(0, 0),
      mapMeasure,
    );

    // Re-add listener after a short delay to allow camera animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_mapCameraListener != null) {
        state.mapController?.camera.addListener(_mapCameraListener!);
      }
    });
  }

  void calculateRouteWithBusinessOverview(PlaceDataModel? place) {
    if (place == null) return;
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

  void calculateRoute({int attempt = 0, bool isRecalculating = false}) {
    if ((state.locationPoints ?? []).isEmpty) return;
    GeoCoordinates? start = state.locationPoints?.firstOrNull?.geoCoordinates;
    GeoCoordinates? end = state.locationPoints?.lastOrNull?.geoCoordinates;

    if (start == null || end == null) return;

    final TruckNavigationState previousState = state;

    void restoreAndMaybeRetry() {
      if (attempt < _maxRouteOrNavigationRetries) {
        emit(previousState);
        Future.microtask(
          () => calculateRoute(
            attempt: attempt + 1,
            isRecalculating: isRecalculating,
          ),
        );
      } else {
        emit(previousState);
      }
    }

    try {
      // Update transport profile before calculating route to ensure restrictions are accurate
      _setupTransportProfile();

      final waypoints = List.generate(
        state.locationPoints!.length,
        (i) => Waypoint(state.locationPoints![i].geoCoordinates!),
      );
      if (!isRecalculating) {
        TruckSpecificationState mySpecs = navigatorKey.currentContext!
            .read<TruckSpecificationsCubit>()
            .state;

        navigatorKey.currentContext!
            .read<RouteTruckSpecificationsCubit>()
            .initSpecs(mainSpecs: mySpecs);
      }

      final truckOptions = _createTruckOptions();

      _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
        RoutingError? error,
        List<Route>? routes,
      ) {
        try {
          if (error != null || routes == null || routes.isEmpty) {
            restoreAndMaybeRetry();
            return;
          }

          final route = routes.first;
          emit(state.copyWith(currentRoute: route, hasDirection: true));
          refreshStopAndDestinationMarker();
          _processTruckRestrictionWarnings(route);
          _showRouteOnMap(route);
        } catch (e, st) {
          log('calculateRoute callback error: $e\n$st');
          restoreAndMaybeRetry();
        }
      });
    } catch (e, st) {
      log('calculateRoute error: $e\n$st');
      restoreAndMaybeRetry();
    }
  }

  TruckOptions _createTruckOptions() {
    TruckSpecificationState mySpecs = navigatorKey.currentContext!
        .read<RouteTruckSpecificationsCubit>()
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
        .read<RouteTruckSpecificationsCubit>()
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

  void _showRouteOnMap(Route route) async {
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

    await Future.delayed(Duration(seconds: 1), () {
      animateToRoute(route);
      minimizeNavigationSheetOn();
    });
  }

  void animateToRoute([Route? route]) {
    final Route? _route = route ?? state.currentRoute;
    if (_route == null) return;

    final viewport = state.mapController!.viewportSize;

    const double leftPadding = 40;
    const double rightPadding = 140;
    const double topUIPadding = 280;
    const double bottomUIPadding = 380;

    const double extraTop = 20;
    const double extraBottom = 20;

    // 👇 ZOOM OUT CONTROL (bigger = more zoomed out)
    const double zoomOutFactor = 1.0; //1.25  try 1.2 – 1.4 sweet spot

    // --- Expand the bounding box ---
    GeoBox box = _route.boundingBox;

    double latSpan =
        box.northEastCorner.latitude - box.southWestCorner.latitude;
    double lonSpan =
        box.northEastCorner.longitude - box.southWestCorner.longitude;

    double latPadding = latSpan * (zoomOutFactor - 1) / 2;
    double lonPadding = lonSpan * (zoomOutFactor - 1) / 2;

    GeoBox expandedBox = GeoBox(
      GeoCoordinates(
        box.southWestCorner.latitude - latPadding,
        box.southWestCorner.longitude - lonPadding,
      ),
      GeoCoordinates(
        box.northEastCorner.latitude + latPadding,
        box.northEastCorner.longitude + lonPadding,
      ),
    );

    // --- UI-aware viewport ---
    Point2D origin = Point2D(leftPadding, topUIPadding + extraTop);

    Size2D sizeInPixels = Size2D(
      viewport.width - leftPadding - rightPadding,
      viewport.height - topUIPadding - bottomUIPadding - extraTop - extraBottom,
    );

    Rectangle2D mapViewport = Rectangle2D(origin, sizeInPixels);

    MapCameraUpdate cameraUpdate =
        MapCameraUpdateFactory.lookAtAreaWithGeoOrientationAndViewRectangle(
          expandedBox, // 👈 use expanded box
          GeoOrientationUpdate(0.0, 0.0),
          mapViewport,
        );

    MapCameraAnimation animation =
        MapCameraAnimationFactory.createAnimationFromUpdateWithEasing(
          cameraUpdate,
          Duration(milliseconds: 2000),
          Easing(EasingFunction.outInSine),
        );

    state.mapController?.camera.startAnimation(animation);
  }

  void startNavigation({int attempt = 0}) {
    if (state.currentRoute == null) return;

    final TruckNavigationState previousState = state;

    void restoreAndMaybeRetry() {
      WakeLockUtils.disable();
      _visualNavigator?.stopRendering();
      if (AppKeys().isSimulation) {
        _simulator?.stopLocating();
        _simulator = null;
      }
      if (attempt < _maxRouteOrNavigationRetries) {
        emit(previousState);
        _updateCurrentLocationMarker();
        Future.microtask(() => startNavigation(attempt: attempt + 1));
      } else {
        emit(previousState);
        _updateCurrentLocationMarker();
      }
    }

    try {
      emit(state.copyWith(isNavigating: true));
      _updateCurrentLocationMarker();
      WakeLockUtils.enable();
      _visualNavigator?.route = state.currentRoute!;
      _visualNavigator?.startRendering(state.mapController!);
      setupTruckRestrictionWarnings();
      setupManeuverUpdates();
      setupSpeedListeners();
      setupHasArrivedListeners();

      // _locationEngine?.stop();
      if (AppKeys().isSimulation) {
        _simulator = HEREPositioningSimulator();

        final LocationListener navigatorForwarder = LocationListener((
          Location location,
        ) {
          _navigator?.onLocationUpdated(location);
          checkNextTarget(location.coordinates);
          _checkOffRouteAndRecalculateIfNeeded(location.coordinates);
        });

        _simulator?.startLocating(
          _visualNavigator!,
          navigatorForwarder,
          state.currentRoute!,
        );

        emit(
          state.copyWith(
            isNavigating: true,
            nextTargetIndex: 1,
            cameraControlledByNavigator: true,
          ),
        );
      } else {
        // _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);
        emit(
          state.copyWith(
            nextTargetIndex: 1,
            isNavigating: true,
            isNavigationCompleted: false,
            maneuverProgresses: [],
            cameraControlledByNavigator: true,
          ),
        );
      }
    } catch (e, st) {
      log('startNavigation error: $e\n$st');
      restoreAndMaybeRetry();
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
      animateToRoute();
    } else {
      resumeCameraControlByNavigator();
    }
  }

  void stopNavigation() {
    WakeLockUtils.disable();
    _visualNavigator?.stopRendering();

    if (AppKeys().isSimulation) {
      _simulator?.stopLocating();
      _simulator = null;
    }
    emit(
      state.copyWith(
        cameraControlledByNavigator: false,
        nextTargetIndex: 1,
        currentSpeed: 'null',
        speedLimit: 'null',
        isNavigating: false,
        isNavigationCompleted: false,
        isOffRoute: false,
        isRecalculatingRoute: false,
        remainingDistanceInMeters: 'null',
        remainingDuration: 'null',
      ),
    );
    _offRouteConsecutiveCount = 0;

    // if (_locationEngine != null && !(AppKeys().isSimulation)) {
    //   _locationEngine?.stop();
    //   _locationEngine?.startWithLocationAccuracy(
    //     LocationAccuracy.navigation,
    //   );
    // }
    animateToRoute();
    _updateCurrentLocationMarker();
  }

  void _clearStartMarker() {
    if (_startMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_startMarker!);
      _startMarker = null;
    }
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

    _clearStartMarker();

    clearAllStopMarker();

    _clearTruckPreviousMarkers();

    emit(
      state.copyWith(
        destinationSuggestions: FutureData<List<PlaceDataModel>>.initial(),
        selectedSuggestion: removeDestination ? 'null' : null,
        destinationCoordinates: removeDestination ? 'null' : null,
        currentRoute: 'null',
        hasDirection: false,
        tappedPlace: 'null',
        nextTargetIndex: 1,
        destinationFromRecent: 'null',
        businessAtAddress: 'null',
        hasdestinationFromRecent: false,
        locationPoints: [],
        maneuverProgresses: [],
        showBusinessOverviewModal: false,
        hasTapDestination: false,
      ),
    );
    _updateCurrentLocationMarker();
    resetCameraToDefault();
    // focusOnCurrentLocation();
  }

  resetCameraToDefault() {
    if (state.startCoordinates == null) return;

    final mapMeasure = MapMeasure(MapMeasureKind.distanceInMeters, 1000);

    MapCameraUpdate cameraUpdate =
        MapCameraUpdateFactory.lookAtPointWithGeoOrientationAndMeasure(
          GeoCoordinatesUpdate.fromGeoCoordinates(state.startCoordinates!),
          GeoOrientationUpdate(0.0, 0.0),
          mapMeasure,
        );

    MapCameraAnimation animation =
        MapCameraAnimationFactory.createAnimationFromUpdateWithEasing(
          cameraUpdate,
          Duration(milliseconds: 2000),
          Easing(EasingFunction.outInSine),
        );

    state.mapController!.camera.startAnimation(animation);
  }

  void setupManeuverUpdates() {
    if (_visualNavigator == null) return;
    _visualNavigator!.routeProgressListener = RouteProgressListener((
      RouteProgress progress,
    ) {
      final sections = progress.sectionProgress;
      final remainingDistanceInMeters = sections.isNotEmpty
          ? sections.last.remainingDistanceInMeters
          : null;
      final remainingDuration = sections.isNotEmpty
          ? sections.last.remainingDuration
          : null;
      emit(
        state.copyWith(
          maneuverProgresses: progress.maneuverProgress,
          remainingDistanceInMeters: remainingDistanceInMeters,
          remainingDuration: remainingDuration,
        ),
      );
    });
  }

  void setupSpeedListeners() {
    if (_visualNavigator == null) return;

    // Listen for current driving speed
    _visualNavigator!.navigableLocationListener = NavigableLocationListener((
      NavigableLocation currentNavigableLocation,
    ) {
      // Store current navigation location for accurate distance calculations
      final currentLocation =
          currentNavigableLocation.originalLocation.coordinates;
      emit(state.copyWith(currentNavigationLocation: currentLocation));

      final drivingSpeed =
          currentNavigableLocation.originalLocation.speedInMetersPerSecond;
      if (drivingSpeed == null) {
        emit(state.copyWith(currentSpeed: "n/a"));
      } else {
        final kmh = (drivingSpeed * 3.6).toInt();
        // Convert km/h to mph (1 km/h = 0.621371 mph)
        final mph = (kmh * 0.621371).round();
        emit(state.copyWith(currentSpeed: "$mph"));
      }
    });

    // Listen for speed limit
    _visualNavigator!.speedLimitListener = SpeedLimitListener((speedLimit) {
      final currentSpeedLimit = speedLimit
          .effectiveSpeedLimitInMetersPerSecond();
      if (currentSpeedLimit == null) {
        emit(state.copyWith(speedLimit: "n/a"));
      } else if (currentSpeedLimit == 0) {
        emit(state.copyWith(speedLimit: "NSL"));
      } else {
        final kmh = (currentSpeedLimit * 3.6).toInt();
        // Convert km/h to mph (1 km/h = 0.621371 mph)
        final mph = (kmh * 0.621371).round();
        emit(state.copyWith(speedLimit: "$mph"));
      }
    });
  }

  void setupHasArrivedListeners() {
    if (_visualNavigator == null) return;
    _visualNavigator?.destinationReachedListener = DestinationReachedListener(
      () {
        log("Destination reached");
        emit(
          state.copyWith(
            isNavigationCompleted: true,
            remainingDistanceInMeters: 'null',
            remainingDuration: 'null',
          ),
        );
      },
    );
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

    // if (hasDestinationConfirmed) {
    final units = await assetToFile(AppImages.redLocationIcon);
    if (units == null) return;

    destIcon = MapImage.withImageDataImageFormatWidthAndHeight(
      units,
      ImageFormat.png,
      80,
      110,
    );
    // } else {
    //   destIcon = MapImage.withFilePathAndWidthAndHeight(
    //     AppImages.greenMapPin,
    //     60,
    //     100,
    //   );
    // }

    _destinationMarker = MapMarker(destinationPoint.geoCoordinates!, destIcon);

    // 👇 THIS FIXES THE JUMPING & OFFSET
    _destinationMarker!.anchor = Anchor2D.withHorizontalAndVertical(0.5, 1.0);

    // Add metadata to identify destination marker when tapped
    final metadata = Metadata();
    metadata.setString("marker_type", "destination");
    _destinationMarker!.metadata = metadata;

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
      if (i == 0) {
        _updateCurrentLocationMarker();
      } else if (i == state.locationPoints!.length - 1) {
        setDestinationMarker(hasDestinationConfirmed: true);
        continue;
      } else {
        await addStopMakerAt(i, hasFocus: false);
      }
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

    // Add metadata to identify stop markers when tapped
    final metadata = Metadata();
    metadata.setString("marker_type", "stop");
    metadata.setString("stop_index", i.toString());
    marker.metadata = metadata;

    state.mapController?.mapScene.addMapMarker(marker);
    _stopMarkers[i] = marker;
    if (hasFocus) focusDestinationWithOffset(markerCoordinate);
  }

  void _clearCurrentLocationMarker() {
    if (_currentLocationMarker != null) {
      state.mapController?.mapScene.removeMapMarker(_currentLocationMarker!);
      _currentLocationMarker = null;
    }
  }

  Future<void> addStartMaker() async {
    final startPoint = state.locationPoints?.firstOrNull;
    if (startPoint == null) return;
    final startCoordinates = startPoint.geoCoordinates;
    if (startCoordinates == null) return;
    _clearStartMarker();

    if (startPoint.isMyLocation) {
      _clearCurrentLocationMarker();
    }
    MapImage markerIcon;
    if (startPoint.isMyLocation) {
      markerIcon = MapImage.withFilePathAndWidthAndHeight(
        AppIcons.myLocIcon,
        60,
        60,
      );
    } else {
      markerIcon = await _createStopMarkerImage(null, 60.0);
    }
    _startMarker = MapMarker(startCoordinates, markerIcon);
    final metadata = Metadata();
    metadata.setString("marker_type", "start");
    _startMarker!.metadata = metadata;
    state.mapController?.mapScene.addMapMarker(_startMarker!);
  }

  editStopMarkerAt(i) {
    clearStopMarkerAt(i);
    addStopMakerAt(i);
  }

  void _handleMapTapForDestination(GeoCoordinates? geoCoordinates) async {
    // Convert screen coordinates to geo coordinates
    if (geoCoordinates == null) return;

    log(
      "🚨 geoCoordinates: lat ${geoCoordinates.latitude} , lon ${geoCoordinates.longitude}",
      name: "_handleMapTapForDestination",
    );
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

    final units = await assetToFile(AppImages.redLocationIcon);
    if (units == null) return;

    final MapImage destIcon = MapImage.withImageDataImageFormatWidthAndHeight(
      units,
      ImageFormat.png,
      80,
      110,
    );

    // MapImage destIcon = MapImage.withFilePathAndWidthAndHeight(
    //   AppImages.greenMapPin,
    //   60,
    //   100,
    // );

    _destinationMarker = MapMarker(geoCoordinates, destIcon);

    // Add metadata to identify destination marker when tapped
    final metadata = Metadata();
    metadata.setString("marker_type", "destination");
    _destinationMarker!.metadata = metadata;

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
          tappedPlace: FutureData<PlaceDataModel>.loading(),
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
                (error) => onPickedPlaceFound(foundPlace?.toPlaceDataModel),
              );
            } else {
              onPickedPlaceFound(foundPlace.toPlaceDataModel);
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

  void onPickedPlaceFound(PlaceDataModel? foundPlace) {
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
        tappedPlace: FutureData<PlaceDataModel>.completed(foundPlace),
      ),
    );
    setDestinationMarker(hasDestinationConfirmed: true);
  }

  void _handleRecentBusinessPlaceForDestination(RecentSearchModel recent) {
    // Emit loading state
    emit(
      state.copyWith(
        hasTapDestination: true,
        destinationCoordinates: recent.geoCoordinates,
        tappedPlace: FutureData<PlaceDataModel>.loading(),
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
              (error) => onPickedPlaceFound(foundPlace?.toPlaceDataModel),
            );
          } else {
            onPickedPlaceFound(foundPlace.toPlaceDataModel);
          }
        } else {
          // Fallback to reverse geocoding if no matching POI found
          _reverseGeocodeDestination(recent.geoCoordinates);
        }
      },
    );
  }

  void _applyTappedDestinationFromReverseGeocode(PlaceDataModel firstPlace) {
    final List<LocationPoint> _list = [];

    if (!firstPlace.isBusiness) {
      _searchBusinessesAtAddress(firstPlace.geoCoordinates);
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
        place: firstPlace,
        pointType: LocationPointType.destination,
      ),
    );
    emit(
      state.copyWith(
        locationPoints: _list,
        tappedPlace: FutureData<PlaceDataModel>.completed(firstPlace),
      ),
    );
  }

  void _reverseGeocodeDestination(GeoCoordinates coords) {
    final cached = PlacesHiveCacheService.instance.getReverseGeocodedPlace(
      coords,
    );
    if (cached != null) {
      _applyTappedDestinationFromReverseGeocode(cached);
      return;
    }

    final SearchOptions options = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    _searchEngine.searchByCoordinates(coords, options, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null) {
        log("Reverse geocoding failed: $error");
        emit(
          state.copyWith(
            tappedPlace: FutureData<PlaceDataModel>.error(
              "Unable to get location details",
            ),
          ),
        );
        return;
      }
      if (places != null && places.isNotEmpty) {
        unawaited(
          PlacesHiveCacheService.instance.putReverseGeocodedPlace(
            coords,
            places.first.toPlaceDataModel,
          ),
        );
        _applyTappedDestinationFromReverseGeocode(
          places.first.toPlaceDataModel,
        );
      } else {
        emit(
          state.copyWith(
            tappedPlace: FutureData<PlaceDataModel>.error(
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

    // clearCurrentRouteDetail();

    emit(
      state.copyWith(
        hasTapDestination: false,
        hasdestinationFromRecent: false,
        destinationCoordinates: 'null',
        destinationFromRecent: 'null',
        selectedSuggestion: 'null',
        tappedPlace: FutureData<PlaceDataModel>.initial(),
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
    calculateRoute(isRecalculating: true);
    // await refreshStopAndDestinationMarker();
  }

  void addStop(dynamic place, {bool isMyLocation = false}) {
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
                    (place as PlaceDataModel).geoCoordinates.latitude &&
                e.geoCoordinates?.longitude == place.geoCoordinates.longitude,
          ) ??
          true;
    }
    if (any) return;

    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    final item = LocationPoint(
      place: place,
      pointType: LocationPointType.stop,
      isMyLocation: isMyLocation,
    );
    // final addIndex = state.locationPoints!.length - 1;
    final addIndex = state.locationPoints!.length;
    _list.insert(addIndex, item);
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: _list.lastOrNull?.geoCoordinates,
      ),
    );
    // addStopMakerAt(addIndex);
    // refreshStopAndDestinationMarker();
    calculateRoute(isRecalculating: true);
  }

  void editStop(int i, dynamic place, {bool isMyLocation = false}) {
    if (place == null) return;
    if ((state.locationPoints ?? []).isEmpty) return;
    // if (i == 0) return;
    // if (i >= (state.locationPoints?.length ?? 0) - 1) return;
    final isDestination = i == (state.locationPoints?.length ?? 0) - 1;
    final List<LocationPoint> _list = List.from(state.locationPoints ?? []);
    _list[i] = _list[i].copyWith(place: place, isMyLocation: isMyLocation);
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: isDestination ? _list[i].geoCoordinates : null,
      ),
    );
    calculateRoute(isRecalculating: true);
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
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: _list.lastOrNull?.geoCoordinates,
      ),
    );
    clearStopMarkerAt(index);
    calculateRoute(isRecalculating: true);
  }

  void searchBusinessDetailsByPlaceId(
    placeId,
    Function(PlaceDataModel? place) onSuccess,
    Function(String? error) onError,
  ) {
    final id = placeId?.toString() ?? '';
    if (id.isEmpty) {
      onError(null);
      onSuccess(null);
      return;
    }
    final cached = PlacesHiveCacheService.instance.getPlaceDetails(id);
    if (cached != null) {
      onSuccess(cached);
      return;
    }

    _searchEngine.searchByPlaceId(PlaceIdQuery(placeId), LanguageCode.enUs, (
      error,
      Place? place,
    ) {
      if (error != null) onError(error.name);
      if (place != null) {
        unawaited(
          PlacesHiveCacheService.instance.putPlaceDetails(
            id,
            place.toPlaceDataModel,
          ),
        );
      }
      onSuccess(place?.toPlaceDataModel);
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
        emit(
          state.copyWith(
            businessAtAddress: (places?[bussinessIndex])?.toPlaceDataModel,
          ),
        );
      }
    });
  }
}
