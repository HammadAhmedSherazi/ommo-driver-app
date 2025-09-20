import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/home/view/truck_navigation/cubit/get_data.dart';

class TruckNavigationState extends Equatable {
  final HereMapController? mapController;
  final FutureData<List<Suggestion>>? destinationSuggestions;
  final GeoCoordinates? startCoordinates;
  final GeoCoordinates? destinationCoordinates;
  final Route? currentRoute;
  final bool isNavigating;
  final bool hasDirection;
  final bool isSimulating;
  final bool cameraControlledByNavigator;
  final ManeuverProgress? maneuverProgress;

  const TruckNavigationState({
    this.mapController,
    this.startCoordinates,
    this.maneuverProgress,
    this.destinationCoordinates,
    this.currentRoute,
    this.isNavigating = false,
    this.hasDirection = false,
    this.cameraControlledByNavigator = false,
    this.destinationSuggestions,
    this.isSimulating = false,
  });

  TruckNavigationState copyWith({
    HereMapController? mapController,
    GeoCoordinates? startCoordinates,
    dynamic destinationCoordinates,
    FutureData<List<Suggestion>>? destinationSuggestions,
    dynamic currentRoute,
    bool? isNavigating,
    bool? isSimulating,
    bool? cameraControlledByNavigator,
    bool? hasDirection,
    dynamic maneuverProgress,
  }) {
    return TruckNavigationState(
      destinationSuggestions: destinationSuggestions ?? this.destinationSuggestions,
      mapController: mapController ?? this.mapController,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      destinationCoordinates: destinationCoordinates == 'null' ? null : (destinationCoordinates ?? this.destinationCoordinates),
      currentRoute: currentRoute == 'null' ? null : (currentRoute ?? this.currentRoute),
      maneuverProgress: maneuverProgress == 'null' ? null : (maneuverProgress ?? this.maneuverProgress),
      isNavigating: isNavigating ?? this.isNavigating,
      isSimulating: isSimulating ?? this.isSimulating,
      cameraControlledByNavigator: cameraControlledByNavigator ?? this.cameraControlledByNavigator,
      hasDirection: hasDirection ?? this.hasDirection,
    );
  }

  @override
  List<Object?> get props => [
    destinationSuggestions,
    mapController,
    startCoordinates,
    destinationCoordinates,
    currentRoute,
    isNavigating,
    isSimulating,
    hasDirection,
    cameraControlledByNavigator,
    maneuverProgress,
  ];
}
