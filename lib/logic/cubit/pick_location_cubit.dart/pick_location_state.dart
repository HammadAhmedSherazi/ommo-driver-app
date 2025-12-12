import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';

class PickLocationState extends Equatable {
  final HereMapController? mapController;
  final FutureData<Place>? selectedPlace;
  final GeoCoordinates? selectedCoordinates;
  final bool isMapLoading;

  const PickLocationState({
    this.mapController,
    this.selectedPlace,
    this.selectedCoordinates,
    this.isMapLoading = true,
  });

  PickLocationState copyWith({
    HereMapController? mapController,
    dynamic selectedPlace,
    dynamic selectedCoordinates,
    bool? isMapLoading,
  }) {
    return PickLocationState(
      mapController: mapController ?? this.mapController,
      selectedPlace: selectedPlace == 'null'
          ? null
          : (selectedPlace ?? this.selectedPlace),
      selectedCoordinates: selectedCoordinates == 'null'
          ? null
          : (selectedCoordinates ?? this.selectedCoordinates),
      isMapLoading: isMapLoading ?? this.isMapLoading,
    );
  }

  @override
  List<Object?> get props => [
    mapController,
    selectedPlace,
    selectedCoordinates,
    isMapLoading,
  ];
}
