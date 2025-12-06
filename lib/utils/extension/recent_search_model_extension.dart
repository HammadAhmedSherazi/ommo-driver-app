import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/theme/theme.dart';

extension RecentSearchModelExtension on RecentSearchModel {
  GeoCoordinates get geoCoordinates => GeoCoordinates(latitude, longitude);

  String get formattedTitle {
    String streetPart = address;

    if (address.contains(',')) {
      final parts = address.split(',');
      streetPart = parts.first.trim();
    }
    return isBussiness ? title : streetPart;
  }

  String get formattedSubTitle {
    String cityPart = address.substring(address.indexOf(',') + 1).trim();

    return isBussiness ? address : cityPart;
  }

  Widget buildSuggestionTitleWidget() {
    return Text(
      formattedTitle,
      maxLines: 1,
      style: AppTextTheme().bodyText.copyWith(
        color: Colors.black,
        fontSize: 16,
      ),
    );
  }

  Widget buildSuggestionSubtitleWidget() {
    return Text(
      formattedSubTitle,
      maxLines: 2,
      style: AppTextTheme().lightText.copyWith(
        color: AppColorTheme().secondary,
      ),
    );
  }
}
