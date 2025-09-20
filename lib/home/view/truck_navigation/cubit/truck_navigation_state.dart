import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/home/view/truck_navigation/cubit/get_data.dart';

class TruckNavigationState {
  final HereMapController? mapController;
  final FutureData<List<Suggestion>>? destinationSuggestions;
  final GeoCoordinates? startCoordinates;
  final GeoCoordinates? destinationCoordinates;
  final Route? currentRoute;
  final bool isNavigating;
  final bool hasDirection;
  final bool isSimulating;

  TruckNavigationState({
    this.mapController,
    this.startCoordinates,
    this.destinationCoordinates,
    this.currentRoute,
    this.isNavigating = false,
    this.hasDirection = false,
    this.destinationSuggestions,
    this.isSimulating = false,
  });

  TruckNavigationState copyWith({
    HereMapController? mapController,
    GeoCoordinates? startCoordinates,
    GeoCoordinates? destinationCoordinates,
    FutureData<List<Suggestion>>? destinationSuggestions,
    Route? currentRoute,
    bool? isNavigating,
    bool? isSimulating,
    bool? hasDirection,
  }) {
    return TruckNavigationState(
      destinationSuggestions: destinationSuggestions ?? this.destinationSuggestions,
      mapController: mapController ?? this.mapController,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
      currentRoute: currentRoute ?? this.currentRoute,
      isNavigating: isNavigating ?? this.isNavigating,
      isSimulating: isSimulating ?? this.isSimulating,
      hasDirection: hasDirection ?? this.hasDirection,
    );
  }
}
