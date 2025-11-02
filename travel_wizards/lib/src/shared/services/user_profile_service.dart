import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_wizards/src/features/onboarding/data/onboarding_state.dart';
import 'package:travel_wizards/src/shared/models/profile_store.dart';
import 'package:travel_wizards/src/shared/models/user_profile.dart';
import 'package:travel_wizards/src/shared/services/offline_service.dart';

class UserProfileService with OfflineCapableMixin {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final ProfileStore _profileStore = ProfileStore.instance;
  final OfflineService _offlineService = OfflineService.instance;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _offlineService.initialize();
    _offlineService.registerPendingActionProcessor(
      'update_profile',
      _processQueuedProfileUpdate,
    );
    _initialized = true;
  }

  Future<UserProfile?> loadProfile({bool forceRefresh = false}) async {
    await ensureInitialized();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (!_profileStore.isLoaded) {
      await _profileStore.load();
    }

    if (!forceRefresh && !_offlineService.isOnline) {
      final cached = _offlineService.getCachedUserProfile();
      if (cached != null) {
        return UserProfile.fromCacheMap(cached);
      }
      return _userProfileFromStore(user.uid);
    }

    try {
      final doc = await _userDoc(user.uid).get();
      if (!doc.exists) {
        return _userProfileFromStore(user.uid);
      }
      final data = doc.data() ?? <String, dynamic>{};
      final profileMap = Map<String, dynamic>.from(
        data['profile'] as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      profileMap['email'] ??= user.email;
      final profile = UserProfile.fromFirestoreMap(user.uid, profileMap);
      await _cacheProfile(profile);
      return profile;
    } catch (e, stack) {
      debugPrint('UserProfileService.loadProfile error: $e');
      debugPrint('$stack');
      final cached = _offlineService.getCachedUserProfile();
      if (cached != null) {
        return UserProfile.fromCacheMap(cached);
      }
      return _userProfileFromStore(user.uid);
    }
  }

  Future<bool> saveProfile(
    UserProfile profile, {
    bool markOnboarded = false,
  }) async {
    await ensureInitialized();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await _profileStore.applyProfile(profile);
    await _offlineService.cacheUserProfile(profile.toCacheMap());

    final actionData = {
      'profile': profile.toFirestoreMap(),
      'uid': user.uid,
      if (markOnboarded) 'hasOnboarded': true,
    };

    final savedOnline = await updateDataWithOfflineSupport(
      'update_profile',
      actionData,
      () async {
        await _userDoc(user.uid).set({
          'profile': profile.toFirestoreMap(),
          if (markOnboarded) 'hasOnboarded': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      },
    );

    if (markOnboarded) {
      OnboardingState.instance.markOnboardedLocally();
    }

    return savedOnline;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    await _profileStore.applyProfile(profile);
    await _offlineService.cacheUserProfile(profile.toCacheMap());
  }

  UserProfile _userProfileFromStore(String uid) {
    return UserProfile(
      uid: uid,
      email: _profileStore.email,
      name: _profileStore.name,
      username: _profileStore.username,
      photoUrl: _profileStore.photoUrl.isEmpty
          ? FirebaseAuth.instance.currentUser?.photoURL
          : _profileStore.photoUrl,
      languageCode: _profileStore.languageCode.isEmpty
          ? null
          : _profileStore.languageCode,
      state: _profileStore.state.isEmpty ? null : _profileStore.state,
      city: _profileStore.city.isEmpty ? null : _profileStore.city,
      country: _profileStore.country.isEmpty ? null : _profileStore.country,
      gender: _profileStore.gender.isEmpty ? null : _profileStore.gender,
      dob: _profileStore.dob.isEmpty
          ? null
          : DateTime.tryParse(_profileStore.dob),
      foodPreferences: _profileStore.foodPref.isEmpty
          ? const <String>[]
          : _profileStore.foodPref
                .split(',')
                .map((e) => e.trim())
                .where((element) => element.isNotEmpty)
                .toList(),
      allergies: _profileStore.allergies.isEmpty
          ? null
          : _profileStore.allergies,
    );
  }

  Future<void> _processQueuedProfileUpdate(Map<String, dynamic> payload) async {
    final uid =
        payload['uid'] as String? ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileMap = Map<String, dynamic>.from(
      payload['profile'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );

    await _userDoc(uid).set({
      'profile': profileMap,
      if (payload['hasOnboarded'] == true) 'hasOnboarded': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final profile = UserProfile.fromFirestoreMap(uid, profileMap);
    await _cacheProfile(profile);
  }
}
