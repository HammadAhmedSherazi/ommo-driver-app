part of 'constants.dart';

class AppKeys {
  AppKeys._internal();

  static final AppKeys _instance = AppKeys._internal();

  factory AppKeys() {
    return _instance;
  }

  static const String onboardingCacheKey = '__onboarding_cache_key__';
}
