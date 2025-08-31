import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';

import 'app/app.dart';

void main()async {
  await _initializeHERESDK();
   WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside-down
  ]);
  runApp( App());
}

Future<void> _initializeHERESDK() async {
  SdkContext.init(IsolateOrigin.main);
  String accessKeyId = "nD9uaWDaZEmcHFyirUGFZw";
  String accessKeySecret =
      "3MSg_BDUhi10ssWBhC_69dR5AzIOmttXg7BpgtsOF_XjKU5xO9LHMFdCF4xh7JvBvggBtgIU0X-PhgTgCjN6Eg";
  AuthenticationMode authenticationMode =
      AuthenticationMode.withKeySecret(accessKeyId, accessKeySecret);
  SDKOptions sdkOptions = SDKOptions.withAuthenticationMode(authenticationMode);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

