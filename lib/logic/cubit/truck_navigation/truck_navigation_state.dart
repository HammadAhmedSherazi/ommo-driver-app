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
  final FutureData<List<Suggestion>>? destinationSuggestions;
  // final FutureData<List<Place>>? nearbyTruckStops;
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
  final int nextTargetIndex;
  final FutureData<List<Place>>? categorySearchResults;
  final List<String>? availableBrands;
  final String? selectedBrand;

  const TruckNavigationState({
    this.mapController,
    this.currentPlace,
    this.startCoordinates,
    this.maneuverProgress,
    this.selectedSuggestion,
    // this.nearbyTruckStops,
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
    this.nextTargetIndex = 1,
    this.categorySearchResults,
    this.availableBrands,
    this.selectedBrand,
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
    dynamic tappedPlace,
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
    int? nextTargetIndex,
    FutureData<List<Place>>? categorySearchResults,
    List<String>? availableBrands,
    String? selectedBrand,
  }) {
    return TruckNavigationState(
      nextTargetIndex: nextTargetIndex ?? this.nextTargetIndex,
      hasFocusedLocation: hasFocusedLocation ?? this.hasFocusedLocation,
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
      tappedPlace: tappedPlace == 'null' ? null : tappedPlace ?? this.tappedPlace,
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
      categorySearchResults: categorySearchResults ?? this.categorySearchResults,
      availableBrands: availableBrands ?? this.availableBrands,
      selectedBrand: selectedBrand == 'null' ? null : (selectedBrand ?? this.selectedBrand),
    );
  }

  @override
  List<Object?> get props => [
    nextTargetIndex,
    locationPoints,
    hasFocusedLocation,
    destinationSuggestions,
    mapController,
    currentPlace,
    // nearbyTruckStops,
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
    categorySearchResults,
    availableBrands,
    selectedBrand,
  ];
}
