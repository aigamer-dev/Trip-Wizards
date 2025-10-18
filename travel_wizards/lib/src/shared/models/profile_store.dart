import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/shared/models/user_profile.dart';

class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const _keyName = 'profile_name';
  static const _keyEmail = 'profile_email';
  static const _keyPhotoUrl = 'profile_photo_url';
  static const _keyDob = 'profile_dob';
  static const _keyState = 'profile_state';
  static const _keyCity = 'profile_city';
  static const _keyCountry = 'profile_country';
  static const _keyFoodPref = 'profile_food_pref';
  static const _keyAllergies = 'profile_allergies';
  static const _keyLanguage = 'profile_language_code';
  static const _keyGender = 'profile_gender';
  static const _keyUsername = 'profile_username';

  String _name = '';
  String _email = '';
  String _photoUrl = '';
  String _dob = '';
  String _state = '';
  String _city = '';
  String _foodPref = '';
  String _allergies = '';
  String _languageCode = '';
  String _gender = '';
  String _username = '';
  String _country = '';
  bool _loaded = false;

  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get dob => _dob; // ISO yyyy-MM-dd
  String get state => _state;
  String get city => _city;
  String get foodPref => _foodPref;
  String get allergies => _allergies;
  String get languageCode => _languageCode;
  String get gender => _gender;
  String get username => _username;
  String get country => _country;
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
    _languageCode = prefs.getString(_keyLanguage) ?? '';
    _gender = prefs.getString(_keyGender) ?? '';
    _username = prefs.getString(_keyUsername) ?? '';
    _country = prefs.getString(_keyCountry) ?? '';
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
    String? country,
    String? foodPref,
    String? allergies,
    String? languageCode,
    String? gender,
    String? username,
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
    if (country != null) {
      _country = country;
      await prefs.setString(_keyCountry, _country);
    }
    if (foodPref != null) {
      _foodPref = foodPref;
      await prefs.setString(_keyFoodPref, _foodPref);
    }
    if (allergies != null) {
      _allergies = allergies;
      await prefs.setString(_keyAllergies, _allergies);
    }
    if (languageCode != null) {
      _languageCode = languageCode;
      await prefs.setString(_keyLanguage, _languageCode);
    }
    if (gender != null) {
      _gender = gender;
      await prefs.setString(_keyGender, _gender);
    }
    if (username != null) {
      _username = username;
      await prefs.setString(_keyUsername, _username);
    }
    notifyListeners();
  }

  Future<void> applyProfile(UserProfile profile) async {
    await update(
      name: profile.name,
      email: profile.email,
      photoUrl: profile.photoUrl,
      dob: profile.dob?.toIso8601String().split('T').first,
      state: profile.state,
      city: profile.city,
      country: profile.country,
      foodPref: profile.foodPreferences.join(', '),
      allergies: profile.allergies,
      languageCode: profile.languageCode,
      gender: profile.gender,
      username: profile.username,
    );
  }
}
