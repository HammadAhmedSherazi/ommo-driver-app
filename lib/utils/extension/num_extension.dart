import 'package:intl/intl.dart';

extension NumExtension on num {
  String get cmtoFeetInchesFormattedString =>
      "${cmToFeetInches['feet']}ft ${cmToFeetInches['inches']}in";

  Map<String, int> get cmToFeetInches {
    double totalInches = this / 2.54;
    int feet = totalInches ~/ 12;
    int inches = (totalInches % 12).round();
    return {"feet": feet, "inches": inches};
  }

  String get kgToLbsFormattedString {
    final lbs = this * 2.20462;
    final formatter = NumberFormat.decimalPattern(); // adds commas
    return "${formatter.format(lbs.round())}lbs";
  }
}
