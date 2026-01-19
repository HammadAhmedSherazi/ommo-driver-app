import 'package:equatable/equatable.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/data/response/get_data.dart';

class TruckStopsState extends Equatable {
  final Place? selectedTruckStop;
  final FutureData<List<Place>>? categorySearchResults;
  final bool showBusinessOverviewModal;
  final List<String>? availableBrands;
  final List<String>? selectedBrands;

  const TruckStopsState({
    this.categorySearchResults,
    this.availableBrands,
    this.selectedBrands,
    this.selectedTruckStop,
    this.showBusinessOverviewModal = false,
  });

  TruckStopsState copyWith({
    FutureData<List<Place>>? categorySearchResults,
    List<String>? availableBrands,
    List<String>? selectedBrands,
    dynamic selectedTruckStop,
    bool? showBusinessOverviewModal,
  }) {
    return TruckStopsState(
      selectedTruckStop: selectedTruckStop == 'null'
          ? null
          : (selectedTruckStop ?? this.selectedTruckStop),
      categorySearchResults:
          categorySearchResults ?? this.categorySearchResults,
      availableBrands: availableBrands ?? this.availableBrands,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      showBusinessOverviewModal:
          showBusinessOverviewModal ?? this.showBusinessOverviewModal,
    );
  }

  @override
  List<Object?> get props => [
    showBusinessOverviewModal,
    selectedTruckStop,
    categorySearchResults,
    availableBrands,
    selectedBrands,
  ];
}
