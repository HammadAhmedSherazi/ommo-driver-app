import 'package:equatable/equatable.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/models/location_point_model.dart';

class CreateTripState extends Equatable {
  final LocationPoint? startPoint;
  final LocationPoint? destinationPoint;
  final LocationPoint? currentStartPoint;

  final bool showRecentTab;
  final bool showYourLocationTab;
  final bool isLoading;
  final bool hasStartFocus;

  final List<Place> startSuggestions;
  final List<Place> destinationSuggestions;

  bool get isMyLocationSelected => startPoint == currentStartPoint;

  const CreateTripState({
    this.startPoint,
    this.destinationPoint,
    this.currentStartPoint,
    this.showRecentTab = true,
    this.showYourLocationTab = false,
    this.isLoading = false,
    this.hasStartFocus = false,
    this.startSuggestions = const [],
    this.destinationSuggestions = const [],
  });

  CreateTripState copyWith({
    LocationPoint? startPoint,
    LocationPoint? destinationPoint,
    LocationPoint? currentStartPoint,
    bool? showRecentTab,
    bool? showYourLocationTab,
    bool? isLoading,
    bool? hasStartFocus,
    List<Place>? startSuggestions,
    List<Place>? destinationSuggestions,
  }) {
    return CreateTripState(
      startPoint: startPoint ?? this.startPoint,
      destinationPoint: destinationPoint ?? this.destinationPoint,
      currentStartPoint: currentStartPoint ?? this.currentStartPoint,
      showRecentTab: showRecentTab ?? this.showRecentTab,
      showYourLocationTab: showYourLocationTab ?? this.showYourLocationTab,
      isLoading: isLoading ?? this.isLoading,
      hasStartFocus: hasStartFocus ?? this.hasStartFocus,
      startSuggestions: startSuggestions ?? this.startSuggestions,
      destinationSuggestions:
          destinationSuggestions ?? this.destinationSuggestions,
    );
  }

  @override
  List<Object?> get props => [
    startPoint,
    destinationPoint,
    currentStartPoint,
    showRecentTab,
    showYourLocationTab,
    isLoading,
    hasStartFocus,
    startSuggestions,
    destinationSuggestions,
  ];
}
