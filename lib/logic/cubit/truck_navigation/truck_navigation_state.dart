import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/models/location_point_model.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';

class TruckNavigationState extends Equatable {
  final HereMapController? mapController;
  final FutureData<List<Place>>? destinationSuggestions;
  final GeoCoordinates? startCoordinates;
  final FutureData<Place>? currentPlace;
  final Suggestion? selectedSuggestion;
  final GeoCoordinates? destinationCoordinates;
  final FutureData<Place>? tappedPlace;
  final bool hasdestinationFromRecent;
  final RecentSearchModel? destinationFromRecent;
  final Route? currentRoute;
  final bool isNavigating;
  final bool isNavigationCompleted;
  final bool hasFocusedLocation;
  final bool isMapLoading;
  final bool hasTapDestination;
  final bool hasDirection;
  final bool cameraControlledByNavigator;
  final List<ManeuverProgress> maneuverProgresses;
  final List<LocationPoint>? locationPoints;
  final int nextTargetIndex;
  final Place? businessAtAddress;
  final String? currentSpeed;
  final String? speedLimit;
  final GeoCoordinates? currentNavigationLocation;
  final bool isUserInteractingWithMap;
  /// Remaining distance to destination in meters (from RouteProgress during navigation).
  final int? remainingDistanceInMeters;
  /// Remaining duration to destination (from RouteProgress during navigation).
  final Duration? remainingDuration;
  /// True when the user has deviated from the route (off-route detection).
  final bool isOffRoute;
  /// True while a new route is being calculated after going off-route.
  final bool isRecalculatingRoute;

  const TruckNavigationState({
    this.mapController,
    this.currentPlace,
    this.startCoordinates,
    this.maneuverProgresses = const [],
    this.selectedSuggestion,
    this.destinationCoordinates,
    this.currentRoute,
    this.tappedPlace,
    this.hasFocusedLocation = false,
    this.isNavigationCompleted = false,
    this.isMapLoading = true,
    this.hasTapDestination = false,
    this.hasdestinationFromRecent = false,
    this.destinationFromRecent,
    this.isNavigating = false,
    this.hasDirection = false,
    this.cameraControlledByNavigator = false,
    this.destinationSuggestions,
    this.locationPoints,
    this.nextTargetIndex = 1,
    this.businessAtAddress,
    this.currentSpeed,
    this.speedLimit,
    this.currentNavigationLocation,
    this.isUserInteractingWithMap = false,
    this.remainingDistanceInMeters,
    this.remainingDuration,
    this.isOffRoute = false,
    this.isRecalculatingRoute = false,
  });

  // GeoCoordinates? get destinationCoordinates =>
  //     selectedSuggestion?.place?.geoCoordinates;

  TruckNavigationState copyWith({
    HereMapController? mapController,
    FutureData<Place>? currentPlace,
    GeoCoordinates? startCoordinates,
    dynamic selectedSuggestion,
    FutureData<List<Place>>? destinationSuggestions,
    FutureData<List<Place>>? nearbyTruckStops,
    dynamic destinationCoordinates,
    dynamic tappedPlace,
    bool? hasdestinationFromRecent,
    bool? isNavigationCompleted,
    dynamic currentRoute,
    bool? hasFocusedLocation,
    bool? isNavigating,
    dynamic destinationFromRecent,
    bool? isMapLoading,
    bool? hasTapDestination,
    bool? showBusinessOverviewModal,
    bool? cameraControlledByNavigator,
    bool? hasDirection,
    List<ManeuverProgress>? maneuverProgresses,
    List<LocationPoint>? locationPoints,
    int? nextTargetIndex,
    dynamic businessAtAddress,
    dynamic currentSpeed,
    dynamic speedLimit,
    GeoCoordinates? currentNavigationLocation,
    bool? isUserInteractingWithMap,
    dynamic remainingDistanceInMeters,
    dynamic remainingDuration,
    bool? isOffRoute,
    bool? isRecalculatingRoute,
  }) {
    return TruckNavigationState(
      nextTargetIndex: nextTargetIndex ?? this.nextTargetIndex,
      hasFocusedLocation: hasFocusedLocation ?? this.hasFocusedLocation,
      isNavigationCompleted:
          isNavigationCompleted ?? this.isNavigationCompleted,
      locationPoints: locationPoints ?? this.locationPoints,
      destinationSuggestions:
          destinationSuggestions ?? this.destinationSuggestions,
      // nearbyTruckStops: nearbyTruckStops ?? this.nearbyTruckStops,
      mapController: mapController ?? this.mapController,
      currentPlace: currentPlace ?? this.currentPlace,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      selectedSuggestion: selectedSuggestion == 'null'
          ? null
          : (selectedSuggestion ?? this.selectedSuggestion),
      destinationCoordinates: destinationCoordinates == 'null'
          ? null
          : (destinationCoordinates ?? this.destinationCoordinates),
      destinationFromRecent: destinationFromRecent == 'null'
          ? null
          : (destinationFromRecent ?? this.destinationFromRecent),
      tappedPlace: tappedPlace == 'null'
          ? null
          : tappedPlace ?? this.tappedPlace,
      currentRoute: currentRoute == 'null'
          ? null
          : (currentRoute ?? this.currentRoute),
      maneuverProgresses: maneuverProgresses ?? this.maneuverProgresses,
      hasdestinationFromRecent:
          hasdestinationFromRecent ?? this.hasdestinationFromRecent,
      isNavigating: isNavigating ?? this.isNavigating,
      isMapLoading: isMapLoading ?? this.isMapLoading,
      cameraControlledByNavigator:
          cameraControlledByNavigator ?? this.cameraControlledByNavigator,
      hasDirection: hasDirection ?? this.hasDirection,
      hasTapDestination: hasTapDestination ?? this.hasTapDestination,
      businessAtAddress: businessAtAddress == "null"
          ? null
          : businessAtAddress ?? this.businessAtAddress,
      currentSpeed: currentSpeed == 'null'
          ? null
          : (currentSpeed ?? this.currentSpeed),
      speedLimit: speedLimit == 'null' ? null : (speedLimit ?? this.speedLimit),
      currentNavigationLocation:
          currentNavigationLocation ?? this.currentNavigationLocation,
      isUserInteractingWithMap:
          isUserInteractingWithMap ?? this.isUserInteractingWithMap,
      remainingDistanceInMeters: remainingDistanceInMeters == 'null'
          ? null
          : (remainingDistanceInMeters ?? this.remainingDistanceInMeters),
      remainingDuration: remainingDuration == 'null'
          ? null
          : (remainingDuration ?? this.remainingDuration),
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isRecalculatingRoute: isRecalculatingRoute ?? this.isRecalculatingRoute,
    );
  }

  @override
  List<Object?> get props => [
    mapController,
    isNavigationCompleted,
    currentPlace,
    startCoordinates,
    maneuverProgresses,
    selectedSuggestion,
    destinationCoordinates,
    currentRoute,
    tappedPlace,
    hasFocusedLocation,
    isMapLoading,
    hasTapDestination,
    hasdestinationFromRecent,
    destinationFromRecent,
    isNavigating,
    hasDirection,
    cameraControlledByNavigator,
    destinationSuggestions,
    locationPoints,
    nextTargetIndex,
    businessAtAddress,
    currentSpeed,
    speedLimit,
    currentNavigationLocation,
    isUserInteractingWithMap,
    remainingDistanceInMeters,
    remainingDuration,
    isOffRoute,
    isRecalculatingRoute,
  ];
}
