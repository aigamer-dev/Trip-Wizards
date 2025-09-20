import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'error_handling_service.dart';

class AuthResult {
  final User user;
  final Map<String, dynamic>? profile;
  AuthResult({required this.user, required this.profile});
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const List<String> _scopes = <String>[
    'email',
    'profile',
    'openid',
    'https://www.googleapis.com/auth/user.birthday.read',
    'https://www.googleapis.com/auth/user.gender.read',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  String? _cachedAvatarUrl;

  Future<AuthResult?> signInWithGoogle() async {
    try {
      UserCredential userCred;
      String? accessTokenForPeople;

      if (kIsWeb) {
        // On Web, use Firebase Auth popup with minimal scopes to avoid blocked consent.
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..addScope('openid');
        provider.setCustomParameters({'prompt': 'select_account'});
        try {
          userCred = await FirebaseAuth.instance.signInWithPopup(provider);
          final cred = userCred.credential;
          if (cred is OAuthCredential) {
            accessTokenForPeople = cred.accessToken;
          }
        } on FirebaseAuthException catch (e) {
          // Fallback to redirect when popups are blocked.
          if (e.code == 'popup-blocked') {
            await FirebaseAuth.instance.signInWithRedirect(provider);
            // After redirect, authStateChanges() will emit the user.
            return null;
          }
          rethrow;
        }
      } else {
        // Mobile/desktop: use google_sign_in with extended scopes.
        final googleSignIn = GoogleSignIn(scopes: _scopes);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; // user cancelled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        accessTokenForPeople = googleAuth.accessToken;
      }

      final user = userCred.user!;

      // Try to fetch People API photo; ignore failures. May be null on web (due to limited scopes).
      String? peoplePhoto;
      try {
        peoplePhoto = await fetchPeoplePhotoUrl(
          accessToken: accessTokenForPeople,
        );
        if (peoplePhoto != null) {
          _cachedAvatarUrl = peoplePhoto;
        }
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'AuthService: Fetching people photo URL',
          showToUser: false,
        );
      }

      // Firestore handshake:
      // - Do NOT overwrite hasOnboarded on sign-in.
      // - Set hasOnboarded=false only when creating a brand new user document or when the field is missing.
      // - Merge only non-null fields to avoid clobbering existing values with null.
      final users = FirebaseFirestore.instance.collection('users');
      final docRef = users.doc(user.uid);
      final existing = await docRef.get();
      final Map<String, dynamic> toMerge = {
        'uid': user.uid,
        'email': user.email,
        'provider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (user.displayName != null) {
        toMerge['name'] = user.displayName;
      }
      final photo = peoplePhoto ?? user.photoURL;
      if (photo != null && photo.isNotEmpty) {
        toMerge['photoUrl'] = photo;
      }
      if (!existing.exists || (existing.data()?['hasOnboarded'] == null)) {
        toMerge['hasOnboarded'] = false;
        toMerge['createdAt'] = FieldValue.serverTimestamp();
      }
      await docRef.set(toMerge, SetOptions(merge: true));
      final snap = await docRef.get();
      return AuthResult(user: user, profile: snap.data());
    } catch (e) {
      // Improve actionable messages for common cases
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google Sign-In configuration error (code 10). Ensure your Android appId and SHA-1/SHA-256 are added in Firebase and refresh google-services.json.',
        );
      }
      if (msg.contains('unauthorized_domain') ||
          msg.contains('origin not allowed')) {
        throw Exception(
          'Unauthorized domain for Google Sign-In. Add your site origin to Firebase Auth → Settings → Authorized domains.',
        );
      }
      if (msg.contains('popup-blocked')) {
        throw Exception(
          'Popup blocked by the browser. Please allow popups for this site or try again.',
        );
      }
      rethrow;
    }
  }

  Future<String?> fetchPeoplePhotoUrl({String? accessToken}) async {
    try {
      // Ensure we have an access token with proper scopes
      String? token = accessToken;
      if (token == null) {
        final g = GoogleSignIn(scopes: _scopes);
        final account = await g.signInSilently();
        final auth = await account?.authentication;
        token = auth?.accessToken;
      }
      if (token == null) return null;
      final uri = Uri.parse(
        'https://people.googleapis.com/v1/people/me?personFields=photos',
      );
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return null;
      final data = convert.jsonDecode(resp.body) as Map<String, dynamic>;
      final photos = (data['photos'] as List?)?.cast<dynamic>() ?? const [];
      String? url;
      for (final p in photos) {
        final m = p as Map<String, dynamic>;
        final isDefault = (m['default'] as bool?) ?? false;
        final u = m['url'] as String?;
        if (u != null && !isDefault) {
          url = u;
          break;
        }
        url ??= u; // fall back to first available
      }
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getPreferredAvatarUrl() async {
    if (_cachedAvatarUrl != null) return _cachedAvatarUrl;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Try People API first
    final peopleUrl = await fetchPeoplePhotoUrl();
    if (peopleUrl != null) {
      _cachedAvatarUrl = peopleUrl;
      // Upsert to Firestore for future fallback
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': peopleUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'AuthService: Updating user photo URL in Firestore',
          showToUser: false,
        );
      }
      return peopleUrl;
    }

    // Then Firestore
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final url = (snap.data() ?? const {})['photoUrl'] as String?;
      if (url != null) {
        _cachedAvatarUrl = url;
        return url;
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'AuthService: Fetching user photo URL from Firestore',
        showToUser: false,
      );
    }

    return null;
  }

  /// Attempts to fetch basic profile details from the People API.
  /// Returns a map like { 'name': String?, 'dob': {year, month, day}, 'gender': String? }
  Future<Map<String, dynamic>?> fetchPeopleProfile() async {
    try {
      final g = GoogleSignIn(scopes: _scopes);
      final account = await g.signInSilently();
      final auth = await account?.authentication;
      final token = auth?.accessToken;
      if (token == null) return null;
      final uri = Uri.parse(
        'https://people.googleapis.com/v1/people/me?personFields=names,genders,birthdays',
      );
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return null;
      final data = convert.jsonDecode(resp.body) as Map<String, dynamic>;
      final result = <String, dynamic>{};
      // Name
      final names = (data['names'] as List?)?.cast<dynamic>() ?? const [];
      if (names.isNotEmpty) {
        final m = names.first as Map<String, dynamic>;
        result['name'] = m['displayName'] as String?;
      }
      // Gender
      final genders = (data['genders'] as List?)?.cast<dynamic>() ?? const [];
      if (genders.isNotEmpty) {
        final m = genders.first as Map<String, dynamic>;
        result['gender'] = (m['value'] as String?)?.toLowerCase();
      }
      // Birthday
      final birthdays =
          (data['birthdays'] as List?)?.cast<dynamic>() ?? const [];
      if (birthdays.isNotEmpty) {
        final b = birthdays.first as Map<String, dynamic>;
        final date = (b['date'] as Map?)?.cast<String, dynamic>();
        if (date != null) {
          result['dob'] = {
            'year': date['year'] as int?,
            'month': date['month'] as int?,
            'day': date['day'] as int?,
          };
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    final users = FirebaseFirestore.instance.collection('users');
    final docRef = users.doc(user.uid);
    final existing = await docRef.get();
    final Map<String, dynamic> toMerge = {
      'uid': user.uid,
      'email': user.email,
      'provider': 'password',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      toMerge['hasOnboarded'] = false;
      toMerge['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(toMerge, SetOptions(merge: true));
    final snap = await docRef.get();
    return AuthResult(user: user, profile: snap.data());
  }

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
    final users = FirebaseFirestore.instance.collection('users');
    final docRef = users.doc(user.uid);
    await docRef.set({
      'uid': user.uid,
      'name': name,
      'email': user.email,
      'provider': 'password',
      'hasOnboarded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final snap = await docRef.get();
    return AuthResult(user: user, profile: snap.data());
  }

  Future<void> signOut() async {
    // Firebase sign out
    await FirebaseAuth.instance.signOut();
    // Try Google sign-out if available
    try {
      final g = GoogleSignIn();
      await g.signOut();
      await g.disconnect();
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'AuthService: Google sign out cleanup',
        showToUser: false,
      );
    }
  }
}
