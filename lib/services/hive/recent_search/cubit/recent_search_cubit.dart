import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/models/models.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/services/hive/recent_search/service/recent_search_services.dart';

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

  Future<void> addSearchFromPlace(PlaceDataModel place) async {
    await _service.addSearch(
      RecentSearchModel(
        title: place.title,
        isBussiness: place.isBusiness,
        address: place.address,
        latitude: place.latitude,
        longitude: place.longitude,
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
