import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as pp;

class LocalStorage {
  final storage = const FlutterSecureStorage();

  Future<bool> setValue(String key, String value) async {
    await storage.write(key: key, value: value);
    return true;
  }

  Future<dynamic> readValue(String key) async {
    return await storage.read(key: key);
  }

  Future<bool> clearValue(String key) async {
    await storage.delete(key: key);
    return true;
  }

  static Future<void> deletePreviousStorage() async {
    File file = File(
        join((await pp.getApplicationSupportDirectory()).path, 'first_launch'));
    if (!file.existsSync()) {
      await const FlutterSecureStorage().deleteAll();
      file.createSync();
    }
  }
}
