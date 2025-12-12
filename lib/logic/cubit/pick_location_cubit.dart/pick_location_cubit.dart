import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart' show GeoCoordinates;
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/logic/cubit/pick_location_cubit.dart/pick_location_state.dart';
import 'package:ommo/utils/helpers/helpers.dart';

class PickLocationCubit extends Cubit<PickLocationState> {
  final GeoCoordinates? initialLocation;

  PickLocationCubit(this.initialLocation) : super(PickLocationState());

  Timer? _debounceTimer;
  void onMapCreated(HereMapController controller) {
    emit(state.copyWith(mapController: controller));
    controller.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (error) {});
    if (initialLocation != null) {
      controller.camera.lookAtPoint(initialLocation!);
    }
    controller.camera.addListener(MapCameraListener(_handleCameraStateChange));
  }

  void _handleCameraStateChange(MapCameraState mapState) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      emit(
        state.copyWith(
          selectedCoordinates: mapState.targetCoordinates,
          selectedPlace: FutureData<Place>.loading(),
        ),
      );
      Helpers.print(state.selectedPlace);
      _reverseGeocode(mapState.targetCoordinates);
    });
  }

  void _reverseGeocode(GeoCoordinates coords) {
    final search = SearchEngine();

    search.searchByCoordinates(coords, SearchOptions(), (
      SearchError? e,
      List<Place>? places,
    ) {
      if (e != null || places == null || places.isEmpty) {
        emit(
          state.copyWith(
            selectedPlace: FutureData<Place>.error(
              e?.name ?? "Address not found of that coordinates",
            ),
          ),
        );
        Helpers.print(state.selectedPlace);
        return;
      }
      print("📍 Address: ${places.first.address.addressText}");
      emit(
        state.copyWith(
          selectedPlace: FutureData<Place>.completed(places.first),
        ),
      );
      Helpers.print(state.selectedPlace);
    });
  }
}
