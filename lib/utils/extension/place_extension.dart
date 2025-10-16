import 'package:here_sdk/search.dart';
import 'package:ommo/home/home.dart';

extension PlaceExtension on Place {
  String get distanceInMiles =>
      ((distanceInMeters ?? 0) / 1609).toStringAsFixed(1);

  String get getReadablePlaceTypeFriendly => switch (placeType) {
    PlaceType.poi => "Place or Business",
    PlaceType.address => "Address Location",
    PlaceType.area => "Neighborhood / City",
    PlaceType.street => "Street",
    PlaceType.intersection => "Street Intersection",
    PlaceType.unknown => "Street Intersection",
  };

  String get getImage {
    String img = '';
    for (var e in details.images) {
      if (img.isNotEmpty) break;
      if (e.source.href.isNotEmpty) {
        img = e.source.href;
      }
    }
    return img;
  }

  PlaceDataModel get toPlaceDataModel => PlaceDataModel.fromJson({
    'networkImage': getImage,
    'title': title,
    'address': address.addressText,
    'storeType': getReadablePlaceTypeFriendly,
    'distance': distanceInMiles,
    'shopStatus': details.openingHours.firstOrNull?.isOpen,
    'time': details.openingHours.firstOrNull?.text.firstOrNull,
    'rating': details.ratings.firstOrNull?.average,
    'reviewCount': details.ratings.firstOrNull?.count,
  });
}
