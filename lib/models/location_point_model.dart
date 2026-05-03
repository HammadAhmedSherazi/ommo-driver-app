import 'package:equatable/equatable.dart';
import 'package:here_sdk/core.dart';
import 'package:ommo/models/models.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';

enum LocationPointType { starting, destination, stop }

class LocationPoint extends Equatable {
  final dynamic place;
  final bool isMyLocation;
  final LocationPointType pointType;
  const LocationPoint({
    this.isMyLocation = false,
    required this.place,
    required this.pointType,
  });

  bool get isRecent => place is RecentSearchModel;

  GeoCoordinates? get geoCoordinates => isRecent
      ? (place as RecentSearchModel?)?.geoCoordinates
      : (place as PlaceDataModel?)?.geoCoordinates;


  String? get title => isMyLocation
      ? "My Location"
      : (isRecent
            ? (place as RecentSearchModel?)?.formattedTitle ?? ''
            : (place as PlaceDataModel?)?.title ?? '');


  String? get subTitle => isRecent
      ? (place as RecentSearchModel?)?.formattedSubTitle ?? ''
      : (place as PlaceDataModel?)?.subtitle ?? '';

  LocationPoint copyWith({
    bool? isMyLocation,
    dynamic place,
    LocationPointType? pointType,
  }) {
    return LocationPoint(
      place: place ?? this.place,
      isMyLocation: isMyLocation ?? this.isMyLocation,
      pointType: pointType ?? this.pointType,
    );
  }

  @override
  List<Object?> get props => [place, pointType, isMyLocation];
}
