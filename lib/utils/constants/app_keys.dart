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
  final String accessKeySecret = "3MSg_BDUhi10ssWBhC_69dR5AzIOmttXg7BpgtsOF_XjKU5xO9LHMFdCF4xh7JvBvggBtgIU0X-PhgTgCjN6Eg";
}
