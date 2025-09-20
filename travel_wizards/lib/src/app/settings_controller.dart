import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/services/settings_repository.dart';
import '../services/error_handling_service.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._internal();
  static final AppSettings instance = AppSettings._internal();

  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale_code';
  static const _keyRemoteIdeasEnabled = 'remote_ideas_enabled';
  static const _keyWifiOnlySync = 'wifi_only_sync';
  static const _keyPrivateMode = 'private_mode';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keySubscriptionTier =
      'subscription_tier'; // free|pro|enterprise

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  bool _remoteIdeasEnabled = true; // gated by compile-time flag as well
  bool _wifiOnlySync = false;
  bool _privateMode = false;
  bool _notificationsEnabled = true;
  String _subscriptionTier = 'enterprise';

  // Guard to avoid recursive remote writes when applying remote settings
  bool _remoteSyncInProgress = false;

  void beginRemoteSync() {
    _remoteSyncInProgress = true;
  }

  void endRemoteSync() {
    _remoteSyncInProgress = false;
  }

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get remoteIdeasEnabled => _remoteIdeasEnabled;
  bool get wifiOnlySync => _wifiOnlySync;
  bool get privateMode => _privateMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get subscriptionTier => _subscriptionTier;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_keyThemeMode);
    switch (mode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    final code = prefs.getString(_keyLocale);
    _locale = (code != null && code.isNotEmpty) ? Locale(code) : null;
    _remoteIdeasEnabled = prefs.getBool(_keyRemoteIdeasEnabled) ?? true;
    _wifiOnlySync = prefs.getBool(_keyWifiOnlySync) ?? false;
    _privateMode = prefs.getBool(_keyPrivateMode) ?? false;
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _subscriptionTier = prefs.getString(_keySubscriptionTier) ?? 'enterprise';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyThemeMode,
      mode == ThemeMode.system
          ? 'system'
          : (mode == ThemeMode.light ? 'light' : 'dark'),
    );
    // Push to remote when authenticated and not in the middle of a remote pull
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'AppSettings: Remote sync after theme mode change',
          showToUser: false,
        );
      }
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_keyLocale);
    } else {
      await prefs.setString(_keyLocale, locale.languageCode);
    }
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }

  Future<void> setRemoteIdeasEnabled(bool enabled) async {
    _remoteIdeasEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemoteIdeasEnabled, enabled);
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }

  Future<void> setWifiOnlySync(bool value) async {
    _wifiOnlySync = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWifiOnlySync, value);
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }

  Future<void> setPrivateMode(bool value) async {
    _privateMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivateMode, value);
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }

  Future<void> setSubscriptionTier(String value) async {
    _subscriptionTier = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubscriptionTier, value);
    if (!_remoteSyncInProgress && FirebaseAuth.instance.currentUser != null) {
      try {
        await SettingsRepository.instance.pushSettings(this);
      } catch (_) {}
    }
  }
}
