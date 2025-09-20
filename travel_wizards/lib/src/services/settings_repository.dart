import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';

class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  DocumentReference<Map<String, dynamic>> _userSettingsDoc(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('settings');
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> pushSettings(AppSettings s) async {
    await _userSettingsDoc(_uid).set({
      'themeMode': s.themeMode.name,
      'locale': s.locale?.languageCode,
      'remoteIdeasEnabled': s.remoteIdeasEnabled,
      'wifiOnlySync': s.wifiOnlySync,
      'privateMode': s.privateMode,
      'notificationsEnabled': s.notificationsEnabled,
      'subscriptionTier': s.subscriptionTier,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> pullInto(AppSettings s) async {
    final doc = await _userSettingsDoc(_uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    // Pull minimal settings; keep local overrides if missing
    s.beginRemoteSync();
    final theme = data['themeMode'] as String?;
    if (theme != null) {
      switch (theme) {
        case 'light':
          await s.setThemeMode(ThemeMode.light);
          break;
        case 'dark':
          await s.setThemeMode(ThemeMode.dark);
          break;
        default:
          await s.setThemeMode(ThemeMode.system);
      }
    }
    final loc = data['locale'] as String?;
    await s.setLocale(loc == null ? null : Locale(loc));
    final remote = data['remoteIdeasEnabled'] as bool?;
    if (remote != null) await s.setRemoteIdeasEnabled(remote);
    final wifi = data['wifiOnlySync'] as bool?;
    if (wifi != null) await s.setWifiOnlySync(wifi);
    final priv = data['privateMode'] as bool?;
    if (priv != null) await s.setPrivateMode(priv);
    final notif = data['notificationsEnabled'] as bool?;
    if (notif != null) await s.setNotificationsEnabled(notif);
    final tier = data['subscriptionTier'] as String?;
    if (tier != null) await s.setSubscriptionTier(tier);
    s.endRemoteSync();
    // After applying remote, ensure Firestore has any new local defaults
    try {
      await pushSettings(s);
    } catch (_) {}
  }
}
