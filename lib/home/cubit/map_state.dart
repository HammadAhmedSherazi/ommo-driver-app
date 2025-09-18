// map_state.dart
import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';

class MapState extends Equatable {
  final HereMapController? mapController;
  final List<Suggestion>? suggestionDestination;
  final List<Route>? availableDestinationRoutes;
  final GeoCoordinates? startCoordinates;
  final GeoCoordinates? destinationCoordinates;

  const MapState({
    this.mapController,
    this.suggestionDestination,
    this.startCoordinates,
    this.destinationCoordinates,
    this.availableDestinationRoutes,
  });

  MapState copyWith({
    HereMapController? mapController,
    List<Suggestion>? suggestionDestination,
    List<Route>? availableDestinationRoutes,
    GeoCoordinates? startCoordinates,
    GeoCoordinates? destinationCoordinates,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      suggestionDestination: suggestionDestination ?? this.suggestionDestination,
      availableDestinationRoutes: availableDestinationRoutes ?? this.availableDestinationRoutes,
      startCoordinates: startCoordinates ?? this.startCoordinates,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
    );
  }

  @override
  List<Object?> get props => [mapController, suggestionDestination, startCoordinates, destinationCoordinates, availableDestinationRoutes];
}
