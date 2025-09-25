import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';

class TruckNavigationState extends Equatable {
  final HereMapController? mapController;
  final FutureData<List<Suggestion>>? destinationSuggestions;
  final GeoCoordinates? startCoordinates;
  final Suggestion? selectedSuggestion;
  final Route? currentRoute;
  final bool isNavigating;
  final bool isMapLoading;
  final bool hasDirection;
  final bool cameraControlledByNavigator;
  final ManeuverProgress? maneuverProgress;

  const TruckNavigationState({
    this.mapController,
    this.startCoordinates,
    this.maneuverProgress,
    this.selectedSuggestion,
    // this.destinationCoordinates,
    this.currentRoute,
    this.isMapLoading = true,
    this.isNavigating = false,
    this.hasDirection = false,
    this.cameraControlledByNavigator = false,
    this.destinationSuggestions,
  });

  GeoCoordinates? get destinationCoordinates => selectedSuggestion?.place?.geoCoordinates;

  TruckNavigationState copyWith({
    HereMapController? mapController,
    GeoCoordinates? startCoordinates,
    dynamic selectedSuggestion,
    FutureData<List<Suggestion>>? destinationSuggestions,
    dynamic currentRoute,
    bool? isNavigating,
    bool? isMapLoading,
    bool? cameraControlledByNavigator,
    bool? hasDirection,
    dynamic maneuverProgress,
  }) {
    return TruckNavigationState(
      destinationSuggestions: destinationSuggestions ?? this.destinationSuggestions,
      mapController: mapController ?? this.mapController,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      selectedSuggestion: selectedSuggestion == 'null' ? null : (selectedSuggestion ?? this.selectedSuggestion),
      currentRoute: currentRoute == 'null' ? null : (currentRoute ?? this.currentRoute),
      maneuverProgress: maneuverProgress == 'null' ? null : (maneuverProgress ?? this.maneuverProgress),
      isNavigating: isNavigating ?? this.isNavigating,
      isMapLoading: isMapLoading ?? this.isMapLoading,
      cameraControlledByNavigator: cameraControlledByNavigator ?? this.cameraControlledByNavigator,
      hasDirection: hasDirection ?? this.hasDirection,
    );
  }

  @override
  List<Object?> get props => [
    destinationSuggestions,
    mapController,
    startCoordinates,
    selectedSuggestion,
    currentRoute,
    isNavigating,
    isMapLoading,
    hasDirection,
    cameraControlledByNavigator,
    maneuverProgress,
  ];
}
