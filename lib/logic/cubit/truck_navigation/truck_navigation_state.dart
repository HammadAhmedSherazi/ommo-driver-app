import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';

class TruckNavigationState extends Equatable {
  final HereMapController? mapController;
  final FutureData<List<Suggestion>>? destinationSuggestions;
  final FutureData<List<Place>>? nearbyTruckStops;
  final GeoCoordinates? startCoordinates;
  final FutureData<Place>? currentPlace;
  final Suggestion? selectedSuggestion;
  final GeoCoordinates? destinationCoordinates;
  final FutureData<Place>? tappedPlace;
  final bool hasdestinationFromRecent;
  final RecentSearchModel? destinationFromRecent;
  final Route? currentRoute;
  final bool isNavigating;
  final bool hasFocusedLocation;
  final bool isMapLoading;
  final bool hasTapDestination;
  final bool hasDirection;
  final bool cameraControlledByNavigator;
  final ManeuverProgress? maneuverProgress;
  final List<LocationPoint>? locationPoints;

  const TruckNavigationState({
    this.mapController,
    this.currentPlace,
    this.startCoordinates,
    this.maneuverProgress,
    this.selectedSuggestion,
    this.nearbyTruckStops,
    this.destinationCoordinates,
    this.currentRoute,
    this.tappedPlace,
    this.hasFocusedLocation = false,
    this.isMapLoading = true,
    this.hasTapDestination = false,
    this.hasdestinationFromRecent = false,
    this.destinationFromRecent,
    this.isNavigating = false,
    this.hasDirection = false,
    this.cameraControlledByNavigator = false,
    this.destinationSuggestions,
    this.locationPoints,
  });

  // GeoCoordinates? get destinationCoordinates =>
  //     selectedSuggestion?.place?.geoCoordinates;

  TruckNavigationState copyWith({
    HereMapController? mapController,
    FutureData<Place>? currentPlace,
    GeoCoordinates? startCoordinates,
    dynamic selectedSuggestion,
    FutureData<List<Suggestion>>? destinationSuggestions,
    FutureData<List<Place>>? nearbyTruckStops,
    dynamic destinationCoordinates,
    FutureData<Place>? tappedPlace,
    bool? hasdestinationFromRecent,
    dynamic currentRoute,
    bool? hasFocusedLocation,
    bool? isNavigating,
    dynamic destinationFromRecent,
    bool? isMapLoading,
    bool? hasTapDestination,
    bool? cameraControlledByNavigator,
    bool? hasDirection,
    dynamic maneuverProgress,
    List<LocationPoint>? locationPoints,
  }) {
    return TruckNavigationState(
      hasFocusedLocation: hasFocusedLocation ?? this.hasFocusedLocation,
      locationPoints: locationPoints ?? this.locationPoints,
      destinationSuggestions:
          destinationSuggestions ?? this.destinationSuggestions,
      nearbyTruckStops: nearbyTruckStops ?? this.nearbyTruckStops,
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
      tappedPlace: tappedPlace ?? this.tappedPlace,
      currentRoute: currentRoute == 'null'
          ? null
          : (currentRoute ?? this.currentRoute),
      maneuverProgress: maneuverProgress == 'null'
          ? null
          : (maneuverProgress ?? this.maneuverProgress),
      hasdestinationFromRecent:
          hasdestinationFromRecent ?? this.hasdestinationFromRecent,
      isNavigating: isNavigating ?? this.isNavigating,
      isMapLoading: isMapLoading ?? this.isMapLoading,
      cameraControlledByNavigator:
          cameraControlledByNavigator ?? this.cameraControlledByNavigator,
      hasDirection: hasDirection ?? this.hasDirection,
      hasTapDestination: hasTapDestination ?? this.hasTapDestination,
    );
  }

  @override
  List<Object?> get props => [
    locationPoints,
    hasFocusedLocation,
    destinationSuggestions,
    mapController,
    currentPlace,
    nearbyTruckStops,
    destinationFromRecent,
    hasdestinationFromRecent,
    startCoordinates,
    selectedSuggestion,
    destinationCoordinates,
    tappedPlace,
    currentRoute,
    isNavigating,
    isMapLoading,
    hasTapDestination,
  ];
}

enum LocationPointType { starting, destination, stop }

class LocationPoint<T> extends Equatable {
  final T place;
  final LocationPointType pointType;
  const LocationPoint({required this.place, required this.pointType});

  bool get isRecent => place is RecentSearchModel;

  GeoCoordinates? get geoCoordinates => isRecent
      ? (place as RecentSearchModel).geoCoordinates
      : (place as Place).geoCoordinates;
  String? get title => isRecent
      ? (place as RecentSearchModel).formattedTitle
      : (place as Place).formattedTitle;
  String? get subTitle => isRecent
      ? (place as RecentSearchModel).formattedSubTitle
      : (place as Place).formattedSubtitle;

  LocationPoint copyWith({LocationPointType? pointType}) {
    return LocationPoint(place: place, pointType: pointType ?? this.pointType);
  }

  @override
  List<Object?> get props => [place, pointType];
}
