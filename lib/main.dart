import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:ommo/utils/constants/constants.dart';

import 'app/app.dart';

void main() async {
  await _initializeHERESDK();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside-down
  ]);
  runApp(App());
}

Future<void> _initializeHERESDK() async {
  SdkContext.init(IsolateOrigin.main);
  AuthenticationMode authenticationMode = AuthenticationMode.withKeySecret(AppKeys().accessKeyId, AppKeys().accessKeySecret);
  SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}
