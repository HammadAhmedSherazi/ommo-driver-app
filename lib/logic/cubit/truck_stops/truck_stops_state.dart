import 'package:equatable/equatable.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';

class TruckStopsState extends Equatable {
  final Place? selectedTruckStop;
  final List<PlaceCategoryTruckStopsState> categoriesSearchState;
  final bool showBusinessOverviewModal;
  final bool isCameraListenerActive;
  final Set<String> searchedCoordinates; // Track searched areas to avoid duplicates
  final String? currentPlaceType; // Track current search category

  const TruckStopsState({
    required this.categoriesSearchState,
    this.selectedTruckStop,
    this.showBusinessOverviewModal = false,
    this.isCameraListenerActive = false,
    this.searchedCoordinates = const {},
    this.currentPlaceType,
  });

  TruckStopsState copyWith({
    List<PlaceCategoryTruckStopsState>? categoriesSearchState,
    List<String>? availableBrands,
    List<String>? selectedBrands,
    dynamic selectedTruckStop,
    bool? showBusinessOverviewModal,
    bool? isCameraListenerActive,
    Set<String>? searchedCoordinates,
    dynamic currentPlaceType,
  }) {
    return TruckStopsState(
      selectedTruckStop: selectedTruckStop == 'null'
          ? null
          : (selectedTruckStop ?? this.selectedTruckStop),
      currentPlaceType: currentPlaceType == 'null'
          ? null
          : (currentPlaceType ?? this.currentPlaceType),
      categoriesSearchState:
          categoriesSearchState ?? this.categoriesSearchState,
      showBusinessOverviewModal:
          showBusinessOverviewModal ?? this.showBusinessOverviewModal,
      isCameraListenerActive:
          isCameraListenerActive ?? this.isCameraListenerActive,
      searchedCoordinates: searchedCoordinates ?? this.searchedCoordinates,
    );
  }

  @override
  List<Object?> get props => [
    showBusinessOverviewModal,
    selectedTruckStop,
    categoriesSearchState,
    isCameraListenerActive,
    searchedCoordinates,
    currentPlaceType,
  ];
}

class PlaceCategoryTruckStopsState extends Equatable {
  final FutureData<List<Place>>? categorySearchResults;
  final List<String>? availableBrands;
  final List<String>? selectedBrands;
  final String? placeCategory; // Track current search category

  const PlaceCategoryTruckStopsState({
    this.categorySearchResults,
    this.availableBrands,
    this.selectedBrands,
    this.placeCategory,
  });

  PlaceCategoryTruckStopsState copyWith({
    FutureData<List<Place>>? categorySearchResults,
    List<String>? availableBrands,
    List<String>? selectedBrands,
    String? placeCategory,
  }) {
    return PlaceCategoryTruckStopsState(
      placeCategory: placeCategory ?? this.placeCategory,
      categorySearchResults:
          categorySearchResults ?? this.categorySearchResults,
      availableBrands: availableBrands ?? this.availableBrands,
      selectedBrands: selectedBrands ?? this.selectedBrands,
    );
  }

  @override
  List<Object?> get props => [
    categorySearchResults,
    availableBrands,
    selectedBrands,
  ];
}
