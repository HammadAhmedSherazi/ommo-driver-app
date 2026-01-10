import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/app/views/app_view.dart';
import 'package:ommo/logic/cubit/create_trip/create_trip_state.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/models/location_point_model.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';

class CreateTripCubit extends Cubit<CreateTripState> {
  final RecentSearchCubit recentSearchCubit;

  CreateTripCubit(this.recentSearchCubit) : super(const CreateTripState());

  Timer? _debounce;
  final SearchEngine _searchEngine = SearchEngine();

  // Initial start location
  void setInitialStartPoint() {
    final startPoint = LocationPoint(
      place: navigatorKey.currentContext
          ?.read<TruckNavigationCubit>()
          .state
          .currentPlace
          ?.data,
      isMyLocation: true,
      pointType: LocationPointType.starting,
    );

    emit(state.copyWith(startPoint: startPoint, currentStartPoint: startPoint));
  }

  // Debounced search
  void _debouncedSearch(String query, bool isStart) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchSuggestions(query, isStart);
    });
  }

  void searchSuggestions(String query, bool isStart) {
    if (isStart) {
      searchPlaces(query, (suggestions) {
        if (!isClosed) emit(state.copyWith(startSuggestions: suggestions));
      });
    } else {
      searchPlaces(query, (suggestions) {
        if (!isClosed) {
          emit(state.copyWith(destinationSuggestions: suggestions));
        }
      });
    }
  }

  void onStartChanged(String value) {
    emit(
      state.copyWith(
        showRecentTab: value.isEmpty,
        showYourLocationTab: value != "Your Location",
      ),
    );
    _debouncedSearch(value == "Your Location" ? "" : value, true);
  }

  void onDestinationChanged(String value) {
    emit(state.copyWith(showRecentTab: value.isEmpty));
    _debouncedSearch(value, false);
  }

  void onStartFocusChanged(bool hasFocus, String value) {
    emit(
      state.copyWith(
        hasStartFocus: hasFocus ? hasFocus : null,
        showRecentTab: value.isEmpty,
        showYourLocationTab: hasFocus && value != "Your Location",
      ),
    );
  }

  void onDestinationFocusChanged(bool hasFocus, String value) {
    if (hasFocus) {
      emit(
        state.copyWith(
          showRecentTab: value.isEmpty,
          hasStartFocus: false,
          showYourLocationTab: false,
        ),
      );
    }
    _debouncedSearch(value, false);
  }

  // Suggestion selection
  void selectCurrentAsStartingPlace() {
    emit(
      state.copyWith(
        startPoint: state.currentStartPoint,
        showYourLocationTab: false,
      ),
    );
    _checkIfBothEntered();
  }

  void selectSuggestion(dynamic place) {
    recentSearchCubit.addSearchFromPlace(place);
    if (state.hasStartFocus) {
      selectStartingPlace(place);
    } else {
      selectDestinationPlace(place);
    }
  }

  void selectStartingPlace(dynamic place) {
    emit(
      state.copyWith(
        startPoint: LocationPoint(
          place: place,
          pointType: LocationPointType.starting,
        ),
        showYourLocationTab: true,
      ),
    );
    _checkIfBothEntered();
  }

  void selectDestinationPlace(dynamic place) {
    emit(
      state.copyWith(
        destinationPoint: LocationPoint(
          place: place,
          pointType: LocationPointType.destination,
        ),
      ),
    );
    _checkIfBothEntered();
  }

  void selectRecentAsLocationPoint(dynamic recentPlace) {
    if (state.hasStartFocus) {
      selectStartingPlace(recentPlace);
    } else {
      selectDestinationPlace(recentPlace);
    }
  }

  void _checkIfBothEntered() {
    if (state.isLoading) return;
    if (state.startPoint == null || state.destinationPoint == null) return;
    final navigationCubit = navigatorKey.currentContext
        ?.read<TruckNavigationCubit>();
    navigationCubit?.createTrip([state.startPoint!, state.destinationPoint!]);
    navigationCubit?.calculateRoute();
    emit(state.copyWith(isLoading: true));
  }

  /// Routing and Navigation Functions
  void searchPlaces(
    String query,
    Function(List<Suggestion>? suggestions) onChanged,
  ) {
    if (query == '') {
      onChanged([]);
      return;
    }

    if (state.currentStartPoint?.geoCoordinates == null) return;
    SearchOptions searchOptions = SearchOptions();
    searchOptions.languageCode = LanguageCode.enUs;
    searchOptions.maxItems = 5;

    TextQueryArea queryArea = TextQueryArea.withCenter(
      state.currentStartPoint!.geoCoordinates!,
    );
    _searchEngine.suggestByText(
      TextQuery.withArea(query, queryArea),
      searchOptions,
      (SearchError? searchError, List<Suggestion>? list) =>
          onChanged(list ?? []),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
