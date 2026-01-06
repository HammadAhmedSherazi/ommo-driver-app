import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/home/home.dart';
import 'package:ommo/utils/theme/theme.dart';

extension PlaceExtension on Place {
  String get distanceInMiles =>
      '${((distanceInMeters ?? 0) / 1609).toStringAsFixed(1)} mi';

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

  bool get isBusiness => placeType == PlaceType.poi;

  Widget buildSuggestionTitleWidget({TextStyle? style}) {
    return Text(
      formattedTitle,
      maxLines: 1,
      style:
          style ??
          AppTextTheme().bodyText.copyWith(color: Colors.black, fontSize: 16),
    );
  }

  String get formattedTitle {
    final fullAddress = address.addressText;
    String streetPart = fullAddress;
    if (fullAddress.contains(',')) {
      final parts = fullAddress.split(',');
      streetPart = parts.first.trim();
    }
    return isBusiness ? title : streetPart;
  }

  String get formattedSubtitle {
    final fullAddress = address.addressText;
    String cityPart = address.addressText
        .substring(fullAddress.indexOf(',') + 1)
        .trim();

    return isBusiness ? fullAddress : cityPart;
  }

  Widget buildSuggestionSubtitleWidget({TextStyle? style}) {
    return Text(
      formattedSubtitle,
      maxLines: 2,
      style:
          style ??
          AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
    );
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

  List<String> get amenitiesAsList {
    final List<String> amenities = [];
    final a = details.truckAmenities;

    if (a == null) return amenities;

    if (a.hasParking) amenities.add('Parking');
    if (a.hasSecureParking) amenities.add('Secure Parking');
    if (a.hasCarWash) amenities.add('Car Wash');
    if (a.hasTruckWash) amenities.add('Truck Wash');
    if (a.hasHighCanopy) amenities.add('High Canopy');
    if (a.hasIdleReductionSystem) amenities.add('Idle Reduction System');
    if (a.hasTruckScales) amenities.add('Truck Scales');
    if (a.hasPowerSupply) amenities.add('Power Supply');
    if (a.hasChemicalToiletDisposal) {
      amenities.add('Chemical Toilet Disposal');
    }
    if (a.hasTruckStop) amenities.add('Truck Stop');
    if (a.hasWifi) amenities.add('Wi-Fi');
    if (a.hasTruckService) amenities.add('Truck Service');
    if (a.hasShower) {
      amenities.add(
        a.showerCount != null ? 'Shower (${a.showerCount})' : 'Shower',
      );
    }

    return amenities;
  }
}
