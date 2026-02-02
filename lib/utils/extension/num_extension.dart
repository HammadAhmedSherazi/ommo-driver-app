import 'package:intl/intl.dart';

extension NumExtension on num {
  String get cmtoFeetInchesFormattedString =>
      "${cmToFeetInches['feet']}ft ${cmToFeetInches['inches']}in";

  num get inchesToCm => this * 2.54;

  String get meterInMiles {
    const metersPerFoot = 0.3048;
    const metersPerMile = 1609.34;

    if (this < metersPerMile) {
      // Show in feet
      double feet = this / metersPerFoot;
      return "${feet.toStringAsFixed(0)} ft";
    } else {
      // Show in miles
      double miles = this / metersPerMile;
      return "${miles.toStringAsFixed(1)} mi";
    }
  }

  Map<String, int> get cmToFeetInches {
    double totalInches = this / 2.54;
    int feet = totalInches ~/ 12;
    int inches = (totalInches % 12).round();
    return {"feet": feet, "inches": inches};
  }

  String get kgToLbsFormattedString {
    final formatter = NumberFormat.decimalPattern();
    return "${formatter.format(kgToLbs.round())}lbs";
  }

  num get metersToFeet => (this * 3.28084).round();
  
  num get feetToMeters => (this / 3.28084).round();

  num get kgToLbs => (this * 2.20462).round();

  num get lbsToKgs => (this / 2.20462).round();
}
