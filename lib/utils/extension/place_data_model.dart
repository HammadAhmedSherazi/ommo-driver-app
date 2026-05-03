import 'package:flutter/material.dart';
import 'package:ommo/home/home.dart';
import 'package:ommo/utils/theme/theme.dart';

extension PlaceDataModelExtension on PlaceDataModel {


  Widget buildSuggestionTitleWidget({TextStyle? style}) {
    return Text(
      title,
      maxLines: 1,
      style:
          style ??
          AppTextTheme().bodyText.copyWith(color: Colors.black, fontSize: 16),
    );
  }



  Widget buildSuggestionSubtitleWidget({TextStyle? style}) {
    return Text(
      subtitle,
      maxLines: 2,
      style:
          style ??
          AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
    );
  }


}
