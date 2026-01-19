part of 'constants.dart';

class AppKeys {
  AppKeys._internal();

  static final AppKeys _instance = AppKeys._internal();

  factory AppKeys() {
    return _instance;
  }

  static const String onboardingCacheKey = '__onboarding_cache_key__';

  final String accessKeyId = "nD9uaWDaZEmcHFyirUGFZw";
  final bool isSimulation = true;
  // New york
  // final GeoCoordinates startCoordinates = GeoCoordinates(52.534924, 13.199499);
  // final GeoCoordinates endCoordinates = GeoCoordinates(52.532767, 13.198141);
  // final GeoCoordinates startCoordinates2 = GeoCoordinates(
  //   40.7064783,
  //   -74.00585,
  // );
  // final GeoCoordinates startCoordinates = GeoCoordinates(
  //   41.6060823,
  //   -87.3228214,
  // );
  final GeoCoordinates startCoordinates = GeoCoordinates(
    33.5311318,
    -112.1854356,
    // 33.682070,
    // -112.203014,
  );
  // final GeoCoordinates startCoordinates = GeoCoordinates(
  //   41.585905,
  //   -87.3038246,
  // );
  final String accessKeySecret =
      "3MSg_BDUhi10ssWBhC_69dR5AzIOmttXg7BpgtsOF_XjKU5xO9LHMFdCF4xh7JvBvggBtgIU0X-PhgTgCjN6Eg";
}
