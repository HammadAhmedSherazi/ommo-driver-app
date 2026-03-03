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
  Timer? _routeRecalculationDebounceTimer;
  static const double _offRouteThresholdMeters =
      50.0; // Distance threshold for off-route detection

  Future<MapImage> _createStopMarkerImage(int? index, [double size = 70.0]) async {
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

  // Setters
  void setInitialLocation(GeoCoordinates coords) {
    emit(state.copyWith(isMapLoading: false, startCoordinates: coords));
    _updateCurrentLocationMarker();
  }

  void setCurrentLocation(GeoCoordinates coords) {
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

      // commenting this to show my location always on the map
      // return;
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
        if (state.startCoordinates != null) {
          final double distance = calculateDistanceInMeters(
            state.startCoordinates!.latitude,
            state.startCoordinates!.longitude,
            initialCoordinates.latitude,
            initialCoordinates.longitude,
          );
          print("has Distance of $distance > 10 ${distance > 10}");
          if (distance > 10) {
            setCurrentLocation(initialCoordinates);
            return;
          }
        } else {
          setInitialLocation(initialCoordinates);
        }
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
                setCurrentLocation(coords);
                return;
              }
            } else {
              setCurrentLocation(coords);
            }
          }
          if (state.isNavigating) {
            setCurrentLocation(coords);
            // Update currentNavigationLocation with raw GPS location for accurate distance calculations
            emit(state.copyWith(currentNavigationLocation: coords));
            _visualNavigator?.onLocationUpdated(location);
            _navigator?.onLocationUpdated(location);
            checkNextTarget(coords);
            // Check if user is off-route and recalculate if needed
            _checkOffRouteAndRecalculate(coords);
          }
        }),
      );

      _locationEngine?.startWithLocationAccuracy(
        LocationAccuracy.bestAvailable,
      );
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

  /// Check if user is off-route and recalculate route if needed
  void _checkOffRouteAndRecalculate(GeoCoordinates currentLocation) {
    if (state.currentRoute == null || !state.isNavigating) return;

    // Cancel any pending recalculation
    _routeRecalculationDebounceTimer?.cancel();

    // Debounce the check to avoid too frequent recalculations
    _routeRecalculationDebounceTimer = Timer(const Duration(seconds: 1), () {
      _performOffRouteCheck(currentLocation);
    });
  }

  /// Perform the actual off-route check
  void _performOffRouteCheck(GeoCoordinates currentLocation) {
    if (state.currentRoute == null || !state.isNavigating) return;

    // Get the route geometry
    final routeGeometry = state.currentRoute!.geometry;

    // Find the nearest point on the route
    double minDistance = double.infinity;
    final routeVertices = routeGeometry.vertices;

    if (routeVertices.length < 2) return;

    for (int i = 0; i < routeVertices.length - 1; i++) {
      final point1 = routeVertices[i];
      final point2 = routeVertices[i + 1];

      // Calculate distance to the line segment
      final distance = _distanceToLineSegment(currentLocation, point1, point2);

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If user is off-route beyond threshold, recalculate
    if (minDistance > _offRouteThresholdMeters) {
      log(
        "User is off-route. Distance: ${minDistance.toStringAsFixed(2)}m. Recalculating route...",
      );
      _recalculateRouteFromCurrentLocation(currentLocation);
    }
  }

  /// Calculate distance from a point to a line segment
  double _distanceToLineSegment(
    GeoCoordinates point,
    GeoCoordinates lineStart,
    GeoCoordinates lineEnd,
  ) {
    // Calculate distance using the formula for point-to-line-segment distance
    final A = point.latitude - lineStart.latitude;
    final B = point.longitude - lineStart.longitude;
    final C = lineEnd.latitude - lineStart.latitude;
    final D = lineEnd.longitude - lineStart.longitude;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      // Line segment is a point
      return calculateDistanceInMeters(
        point.latitude,
        point.longitude,
        lineStart.latitude,
        lineStart.longitude,
      );
    }

    final param = dot / lenSq;
    GeoCoordinates closestPoint;

    if (param < 0) {
      closestPoint = lineStart;
    } else if (param > 1) {
      closestPoint = lineEnd;
    } else {
      closestPoint = GeoCoordinates(
        lineStart.latitude + param * C,
        lineStart.longitude + param * D,
      );
    }

    return calculateDistanceInMeters(
      point.latitude,
      point.longitude,
      closestPoint.latitude,
      closestPoint.longitude,
    );
  }

  /// Recalculate route from current location to destination
  void _recalculateRouteFromCurrentLocation(GeoCoordinates currentLocation) {
    if (state.locationPoints == null || state.locationPoints!.isEmpty) return;

    // Get destination (last waypoint)
    final destination = state.locationPoints!.lastOrNull;
    if (destination == null || destination.geoCoordinates == null) return;

    // Build waypoints list for recalculation
    final waypoints = <Waypoint>[];

    // Add current location as first waypoint
    waypoints.add(Waypoint(currentLocation));

    // Add remaining waypoints (stops and destination) that haven't been reached
    if (state.locationPoints!.length > 1) {
      // Start from nextTargetIndex to include remaining stops
      final startIndex = state.nextTargetIndex > 0
          ? state.nextTargetIndex - 1
          : 0;

      for (int i = startIndex; i < state.locationPoints!.length; i++) {
        final waypoint = state.locationPoints![i];
        if (waypoint.geoCoordinates != null) {
          waypoints.add(Waypoint(waypoint.geoCoordinates!));
        }
      }
    }

    // Recalculate route
    _setupTransportProfile();
    final truckOptions = _createTruckOptions();

    _routingEngine.calculateTruckRoute(waypoints, truckOptions, (
      RoutingError? error,
      List<Route>? routes,
    ) {
      if (error != null) {
        log("Route recalculation error: $error");
        return;
      }

      if (routes == null || routes.isEmpty) {
        log("No routes found during recalculation");
        return;
      }

      final newRoute = routes.first;
      log(
        "Route recalculated successfully. New route length: ${newRoute.lengthInMeters}m",
      );

      // Update the route
      emit(state.copyWith(currentRoute: newRoute, hasDirection: true));

      // Update visual navigator with new route
      if (_visualNavigator != null && state.isNavigating) {
        _visualNavigator!.route = newRoute;
      }

      // Refresh map display
      refreshStopAndDestinationMarker();
      _processTruckRestrictionWarnings(newRoute);
      _showRouteOnMap(newRoute);

      // // Update location points with reverse geocoded place for current location
      // _updateLocationPointsWithCurrentLocation(currentLocation);
    });
  }

  /// Update location points with reverse geocoded place for current location
  void _updateLocationPointsWithCurrentLocation(
    GeoCoordinates currentLocation,
  ) {
    if (state.locationPoints == null || state.locationPoints!.isEmpty) return;

    final searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 1;

    _searchEngine.searchByCoordinates(currentLocation, searchOptions, (
      SearchError? error,
      List<Place>? places,
    ) {
      if (error != null || places == null || places.isEmpty) {
        // If reverse geocoding fails, keep existing location points
        return;
      }

      final currentLocationPlace = places.first;
      final remainingWaypoints = <LocationPoint>[];

      // Add current location as new starting point
      remainingWaypoints.add(
        LocationPoint(
          place: currentLocationPlace,
          pointType: LocationPointType.starting,
          isMyLocation: true,
        ),
      );

      // Add remaining waypoints (stops and destination)
      if (state.locationPoints!.length > 1) {
        final startIndex = state.nextTargetIndex > 0
            ? state.nextTargetIndex - 1
            : 0;

        for (int i = startIndex; i < state.locationPoints!.length; i++) {
          final waypoint = state.locationPoints![i];
          if (waypoint.geoCoordinates != null) {
            remainingWaypoints.add(waypoint);
          }
        }
      }

      // Update location points
      emit(state.copyWith(locationPoints: remainingWaypoints));
    });
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
      emit(state.copyWith(currentRoute: route, hasDirection: true));
      refreshStopAndDestinationMarker();
      _processTruckRestrictionWarnings(route);
      _showRouteOnMap(route);
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

  // void animateToRoute([Route? route]) {
  //   final Route? _route = route ?? state.currentRoute;
  //   if (_route == null) return;

  //   final viewport = state.mapController!.viewportSize;

  //   // 👇 tune these
  //   const double leftPadding = 180;
  //   const double rightPadding = 180;
  //   const double topPadding = 380; // BIGGER = route appears lower
  //   const double bottomPadding = 280; // smaller bottom padding

  //   Point2D origin = Point2D(leftPadding, topPadding);

  //   Size2D sizeInPixels = Size2D(
  //     viewport.width - leftPadding - rightPadding,
  //     viewport.height - topPadding - bottomPadding,
  //   );

  //   Rectangle2D mapViewport = Rectangle2D(origin, sizeInPixels);

  //   MapCameraUpdate cameraUpdate =
  //       MapCameraUpdateFactory.lookAtAreaWithGeoOrientationAndViewRectangle(
  //         _route.boundingBox,
  //         GeoOrientationUpdate(0.0, 0.0),
  //         mapViewport,
  //       );

  //   MapCameraAnimation animation =
  //       MapCameraAnimationFactory.createAnimationFromUpdateWithEasing(
  //         cameraUpdate,
  //         Duration(milliseconds: 2000),
  //         Easing(EasingFunction.outInSine),
  //       );

  //   state.mapController?.camera.startAnimation(animation);
  // }
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
    const double zoomOutFactor = 1.25; // try 1.2 – 1.4 sweet spot

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

  void startNavigation() {
    if (state.currentRoute == null) return;

    WakeLockUtils.enable();
    _clearCurrentLocationMarker();
    _clearStartMarker();
    _visualNavigator?.route = state.currentRoute!;
    _visualNavigator?.startRendering(state.mapController!);
    setupTruckRestrictionWarnings();
    setupManeuverUpdates();
    setupSpeedListeners();
    setupHasArrivedListeners();

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
        // Check if user is off-route and recalculate if needed
        _checkOffRouteAndRecalculate(location.coordinates);
      });

      _simulator?.startLocating(
        _visualNavigator!,
        navigatorForwarder,
        state.currentRoute!,
      );
    } else {
      _locationEngine?.startWithLocationAccuracy(LocationAccuracy.navigation);
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
        remainingDistanceInMeters: 'null',
        remainingDuration: 'null',
      ),
    );

    if (_locationEngine != null && !(AppKeys().isSimulation)) {
      _locationEngine?.startWithLocationAccuracy(
        LocationAccuracy.bestAvailable,
      );
    }
    animateToRoute();
    _updateCurrentLocationMarker();
    // clearCurrentRouteDetail();
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
        destinationSuggestions: FutureData<List<Suggestion>>.initial(),
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
      final remainingDuration =
          sections.isNotEmpty ? sections.last.remainingDuration : null;
      emit(state.copyWith(
        maneuverProgresses: progress.maneuverProgress,
        remainingDistanceInMeters: remainingDistanceInMeters,
        remainingDuration: remainingDuration,
      ));
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
        emit(state.copyWith(
          isNavigationCompleted: true,
          remainingDistanceInMeters: 'null',
          remainingDuration: 'null',
        ));
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
    final MapImage markerIcon = await _createStopMarkerImage(null, 60.0);
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
        tappedPlace: FutureData<Place>.completed(foundPlace),
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
            tappedPlace: FutureData<Place>.error(
              "Unable to get location details",
            ),
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
            tappedPlace: FutureData<Place>.completed(places.first),
          ),
        );
      } else {
        emit(
          state.copyWith(
            tappedPlace: FutureData<Place>.error(
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
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: _list.lastOrNull?.geoCoordinates,
      ),
    );
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
    _list[i] = _list[i].copyWith(place: place, isMyLocation: false);
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
    emit(
      state.copyWith(
        locationPoints: _list,
        destinationCoordinates: _list.lastOrNull?.geoCoordinates,
      ),
    );
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
