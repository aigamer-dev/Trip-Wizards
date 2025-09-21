import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const _keyName = 'profile_name';
  static const _keyEmail = 'profile_email';
  static const _keyPhotoUrl = 'profile_photo_url';
  static const _keyDob = 'profile_dob';
  static const _keyState = 'profile_state';
  static const _keyCity = 'profile_city';
  static const _keyFoodPref = 'profile_food_pref';
  static const _keyAllergies = 'profile_allergies';

  String _name = '';
  String _email = '';
  String _photoUrl = '';
  String _dob = '';
  String _state = '';
  String _city = '';
  String _foodPref = '';
  String _allergies = '';
  bool _loaded = false;

  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get dob => _dob; // ISO yyyy-MM-dd
  String get state => _state;
  String get city => _city;
  String get foodPref => _foodPref;
  String get allergies => _allergies;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_keyName) ?? '';
    _email = prefs.getString(_keyEmail) ?? '';
    _photoUrl = prefs.getString(_keyPhotoUrl) ?? '';
    _dob = prefs.getString(_keyDob) ?? '';
    _state = prefs.getString(_keyState) ?? '';
    _city = prefs.getString(_keyCity) ?? '';
    _foodPref = prefs.getString(_keyFoodPref) ?? '';
    _allergies = prefs.getString(_keyAllergies) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> update({
    String? name,
    String? email,
    String? photoUrl,
    String? dob,
    String? state,
    String? city,
    String? foodPref,
    String? allergies,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      _name = name;
      await prefs.setString(_keyName, _name);
    }
    if (email != null) {
      _email = email;
      await prefs.setString(_keyEmail, _email);
    }
    if (photoUrl != null) {
      _photoUrl = photoUrl;
      await prefs.setString(_keyPhotoUrl, _photoUrl);
    }
    if (dob != null) {
      _dob = dob;
      await prefs.setString(_keyDob, _dob);
    }
    if (state != null) {
      _state = state;
      await prefs.setString(_keyState, _state);
    }
    if (city != null) {
      _city = city;
      await prefs.setString(_keyCity, _city);
    }
    if (foodPref != null) {
      _foodPref = foodPref;
      await prefs.setString(_keyFoodPref, _foodPref);
    }
    if (allergies != null) {
      _allergies = allergies;
      await prefs.setString(_keyAllergies, _allergies);
    }
    notifyListeners();
  }
}
