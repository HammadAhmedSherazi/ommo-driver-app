import 'package:intl/intl.dart';

extension NumExtension on num {
  String get cmtoFeetInchesFormattedString =>
      "${cmToFeetInches['feet']}ft ${cmToFeetInches['inches']}in";

  num get inchesToCm => this * 2.54;

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

  num get kgToLbs => (this * 2.20462).round();

  num get lbsToKgs => (this / 2.20462).round();
}
