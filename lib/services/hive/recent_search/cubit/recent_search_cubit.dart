import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/services/hive/recent_search/service/recent_search_services.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'recent_search_state.dart';

class RecentSearchCubit extends Cubit<RecentSearchState> {
  final RecentSearchService _service;

  RecentSearchCubit(this._service) : super(const RecentSearchState()) {
    loadRecent();
  }

  void loadRecent() {
    emit(state.copyWith(isLoading: true));

    final items = _service.getRecentSearches();
    emit(state.copyWith(searches: items, isLoading: false));
  }

  Future<void> addSearch(RecentSearchModel model) async {
    await _service.addSearch(model);
    loadRecent();
  }

  Future<void> addSearchFromPlace(Place place) async {
    await _service.addSearch(
      RecentSearchModel(
        title: place.title,
        isBussiness: place.isBusiness,
        address: place.address.addressText,
        latitude: place.geoCoordinates!.latitude,
        longitude: place.geoCoordinates!.longitude,
      ),
    );
    loadRecent();
  }

  Future<void> deleteAt(int index) async {
    await _service.removeAt(index);
    loadRecent();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    loadRecent();
  }
}
