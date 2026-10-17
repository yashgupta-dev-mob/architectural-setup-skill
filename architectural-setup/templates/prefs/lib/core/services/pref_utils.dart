// ignore_for_file: avoid_print
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;

  PrefUtils() {
    if (_sharedPreferences == null) {
      init();
    }
  }

  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<void> clearPreferencesData() async {
    await _sharedPreferences?.clear();
  }

  Future<bool> setString({required String key, required String value}) async {
    return await _sharedPreferences?.setString(key, value) ?? false;
  }

  String? getString({required String key}) {
    return _sharedPreferences?.getString(key);
  }

  Future<bool> setJsonString({
    required String key,
    required String jsonValue,
  }) async {
    return await _sharedPreferences?.setString(key, jsonValue) ?? false;
  }

  String? getJsonString({required String key}) {
    return _sharedPreferences?.getString(key);
  }

  Future<bool> remove({required String key}) async {
    return await _sharedPreferences?.remove(key) ?? false;
  }

  String? getUserToken() {
    return _sharedPreferences?.getString('xx-token');
  }

  Future<bool> setBool({required String key, required bool value}) async {
    return await _sharedPreferences?.setBool(key, value) ?? false;
  }

  bool? getBool({required String key}) {
    return _sharedPreferences?.getBool(key);
  }

  Map<String, dynamic> getAllData() {
    final keys = _sharedPreferences?.getKeys() ?? {};
    final Map<String, dynamic> allData = {};
    for (var key in keys) {
      allData[key] = _sharedPreferences?.get(key);
    }
    log("ALL PREFERNECE DATA");
    print(allData);
    return allData;
  }

  Future<bool> clearAll() {
    return _sharedPreferences?.clear() ?? Future.value(false);
  }
}
