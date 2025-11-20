import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {

  late SharedPreferences _prefs;
  static  final SharedPreferencesService _instance= SharedPreferencesService._();

  factory SharedPreferencesService() {
    return _instance;
  }

  SharedPreferencesService._(); // Private constructor

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

// Set a Int value in SharedPreferences
  Future<bool> setValue(String key, int value) async {
   return  await _prefs.setInt(key, value);
  }

// Get a Int value from SharedPreferences
  int getValue(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // Set a Int value in SharedPreferences
  Future<bool> setDouble(String key, double value) async {
    return  await _prefs.setDouble(key, value);
  }

// Get a Int value from SharedPreferences
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // Set a string value in SharedPreferences
  Future<bool> setString(String key, String value) async {
   return  await _prefs.setString(key, value);
  }

  // Get a string value from SharedPreferences
  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  // Set a string value in SharedPreferences
  Future<bool> setBoolean(String key, bool value) async {
    return  await _prefs.setBool(key, value);
  }

  // Get a string value from SharedPreferences
  bool getBoolean(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // Clear a specific key from SharedPreferences
  Future<void> clearKey(String key) async {
    await _prefs.remove(key);
  }

  // Clear all data from SharedPreferences
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
