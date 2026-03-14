part of 'constants.dart';

class AppApis {
  AppApis._internal();

  static final AppApis _instance = AppApis._internal();

  factory AppApis() {
    return _instance;
  }

  /// Local
  // static const String baseUrl = "http://192.168.200.210:8000";

  /// Staging
  static const String baseUrl = "https://ommo.ai/driver-api";

  static const String baseApiUrl = "$baseUrl/api/";
  static const String login = '$baseApiUrl/Auth/login';
  static const String register = '$baseApiUrl/Auth/signup';
  static const String logout = '$baseApiUrl/Auth/logout';

  /// User profile
  static const String userProfile = '${baseApiUrl}Driver/info';
  static const String userProfileUpdate = '${baseApiUrl}UserDriver/update';

  initBaseUrlAndAuthEndpoints() {
    ApiConfig.baseUrl = baseApiUrl;
    // AuthenticationEndpoints.login = login;
    // AuthenticationEndpoints.register = register;
    // AuthenticationEndpoints.logout = logout;
  }
}
