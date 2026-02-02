part of 'constants.dart';

class AppKeys {
  AppKeys._internal();

  static final AppKeys _instance = AppKeys._internal();

  factory AppKeys() {
    return _instance;
  }

  static const String onboardingCacheKey = '__onboarding_cache_key__';

  final String accessKeyId = "nD9uaWDaZEmcHFyirUGFZw";
  final bool isSimulation = false;
  final GeoCoordinates startCoordinates = GeoCoordinates(
    33.6820707,
    -112.2164676,
    // 32.317206,
    // -106.780645,
  );
  final String accessKeySecret =
      "3MSg_BDUhi10ssWBhC_69dR5AzIOmttXg7BpgtsOF_XjKU5xO9LHMFdCF4xh7JvBvggBtgIU0X-PhgTgCjN6Eg";
}
