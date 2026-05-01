import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ommo/services/hive/places_cache/places_cache_service.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/constants/constants.dart';

import 'app/app.dart';

void main() async {
  await _initializeHERESDK();
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(RecentSearchModelAdapter());
  await Hive.openBox<RecentSearchModel>('recent_search_box');
  await PlacesCacheService().init();
  await SystemChrome.setPreferredOrientations([
  
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(App());
}

Future<void> _initializeHERESDK() async {
  SdkContext.init(IsolateOrigin.main);
  AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret(
    AppKeys().accessKeyId,
    AppKeys().accessKeySecret,
  );
  SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}
