import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';

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
  final bool isMapLoading;
  final bool hasTapDestination;
  final bool hasDirection;
  final bool cameraControlledByNavigator;
  final ManeuverProgress? maneuverProgress;

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
    this.isMapLoading = true,
    this.hasTapDestination = false,
    this.hasdestinationFromRecent = false,
    this.destinationFromRecent,
    this.isNavigating = false,
    this.hasDirection = false,
    this.cameraControlledByNavigator = false,
    this.destinationSuggestions,
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
    bool? isNavigating,
    dynamic destinationFromRecent,
    bool? isMapLoading,
    bool? hasTapDestination,
    bool? cameraControlledByNavigator,
    bool? hasDirection,
    dynamic maneuverProgress,
  }) {
    return TruckNavigationState(
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
