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
  static const String baseUrl = "https://api-app.mmcgbl.dev";

  static const String baseApiUrl = "$baseUrl/api/";
  static const String login = 'login';
  static const String register = 'register';
  static const String logout = 'logout';

  initBaseUrlAndAuthEndpoints() {
    ApiConfig.baseUrl = baseApiUrl;
    // AuthenticationEndpoints.login = login;
    // AuthenticationEndpoints.register = register;
    // AuthenticationEndpoints.logout = logout;
  }
}
