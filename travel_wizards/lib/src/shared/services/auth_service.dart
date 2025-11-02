import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'error_handling_service.dart';
import 'package:travel_wizards/firebase_options.dart';

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

  // Wait until FirebaseAuth.currentUser is non-null (or timeout)
  Future<User?> _waitForFirebaseUser({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    // First, prefer the stream to emit a user
    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(timeout);
      return user;
    } catch (_) {
      // Fall back to polling currentUser briefly
      while (DateTime.now().isBefore(deadline)) {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) return u;
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return FirebaseAuth.instance.currentUser; // may be null
    }
  }

  /// Force redirect-based Google Sign-In (use if popup gets stuck)
  Future<void> forceGoogleSignInRedirect() async {
    if (!kIsWeb) {
      throw Exception('Redirect sign-in is only available on web platforms');
    }

    try {
      debugPrint('🚨 Forcing redirect-based sign-in...');

      // Clear any existing auth state
      await FirebaseAuth.instance.signOut();

      // Force redirect with minimal configuration
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});

      await FirebaseAuth.instance.signInWithRedirect(provider);
    } catch (e) {
      debugPrint('🚨 Force redirect failed: $e');
      rethrow;
    }
  }

  /// Alternative Google Sign-In method using redirect-only approach
  /// Use this if popup-based sign-in continues to fail
  Future<void> signInWithGoogleRedirect() async {
    if (!kIsWeb) {
      throw Exception('Redirect sign-in is only available on web platforms');
    }

    try {
      // Clear any existing state
      await FirebaseAuth.instance.signOut();

      debugPrint('🔄 Initiating Google Sign-In via redirect...');

      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: _scopes);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-In aborted by user');
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('🚨 Redirect sign-in failed: $e');
      rethrow;
    }
  }

  /// Check if we're returning from a Google Sign-In redirect
  Future<AuthResult?> handleRedirectResult() async {
    if (!kIsWeb) return null;

    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      if (result.user == null) return null;

      debugPrint('✅ Successfully handled redirect result');

      // Process the signed-in user same as popup flow
      final user = result.user!;
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
      if (user.photoURL != null) {
        toMerge['photoUrl'] = user.photoURL;
      }
      if (!existing.exists || (existing.data()?['hasOnboarded'] == null)) {
        toMerge['hasOnboarded'] = false;
        toMerge['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(toMerge, SetOptions(merge: true));
      final snap = await docRef.get();

      return AuthResult(user: user, profile: snap.data());
    } catch (e) {
      debugPrint('❌ Error handling redirect result: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> diagnoseGoogleSignInConfig() async {
    final diagnosis = <String, dynamic>{};

    try {
      // Check Firebase initialization
      diagnosis['firebase_initialized'] = Firebase.apps.isNotEmpty;

      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      diagnosis['current_user'] = currentUser?.uid ?? 'none';

      // Check platform
      diagnosis['platform'] = kIsWeb ? 'web' : 'mobile';

      // Check domain for web
      if (kIsWeb) {
        // Note: This would need dart:html import, using placeholder
        diagnosis['current_domain'] = 'check browser location';
      }

      // Check Firebase config
      final options = DefaultFirebaseOptions.currentPlatform;
      diagnosis['project_id'] = options.projectId;
      diagnosis['auth_domain'] = options.authDomain;

      debugPrint('🔍 Google Sign-In Diagnosis: $diagnosis');
      return diagnosis;
    } catch (e) {
      diagnosis['error'] = e.toString();
      debugPrint('❌ Diagnosis failed: $e');
      return diagnosis;
    }
  }

  Future<AuthResult?> signInWithGoogle() async {
    try {
      // Ensure Firebase is properly initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Pre-flight check for web
      if (kIsWeb) {
        debugPrint('🌐 Web Sign-In Attempt');
        debugPrint(
          '  Project: ${DefaultFirebaseOptions.currentPlatform.projectId}',
        );
        debugPrint(
          '  Auth Domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}',
        );
        debugPrint(
          '  API Key: ${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0, 10)}...',
        );
        // Useful for matching Google OAuth "Authorized JavaScript origins"
        try {
          debugPrint('  Origin: ${Uri.base.origin}  (path: ${Uri.base.path})');
        } catch (_) {}

        // Ensure auth state persists across page reloads and redirects on web
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          debugPrint('✅ Firebase Auth persistence set to LOCAL');
        } catch (pErr1) {
          debugPrint('⚠️ LOCAL persistence failed: $pErr1 (trying SESSION)');
          try {
            await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
            debugPrint('✅ Firebase Auth persistence set to SESSION');
          } catch (pErr2) {
            debugPrint(
              '⚠️ SESSION persistence failed: $pErr2 (falling back to NONE)',
            );
            try {
              await FirebaseAuth.instance.setPersistence(Persistence.NONE);
              debugPrint('✅ Firebase Auth persistence set to NONE');
            } catch (pErr3) {
              debugPrint('🚨 All persistence modes failed: $pErr3');
            }
          }
        }

        // Wait a moment for Firebase to be fully ready
        await Future.delayed(const Duration(milliseconds: 100));
      }

      UserCredential userCred;
      String? accessTokenForPeople;

      if (kIsWeb) {
        // Web-specific authentication with timeout
        try {
          debugPrint('🌐 Starting web authentication flow...');

          // Check if we're returning from a redirect first
          final result = await FirebaseAuth.instance.getRedirectResult();
          if (result.user != null) {
            debugPrint('🔄 Successfully returned from redirect');
            userCred = result;
            final cred = result.credential;
            if (cred is OAuthCredential) {
              accessTokenForPeople = cred.accessToken;
            }
            // Ensure auth state is fully applied
            final u = await _waitForFirebaseUser();
            if (kDebugMode) {
              debugPrint(
                '👤 Auth state after redirect: user=${u?.uid ?? 'null'}',
              );
            }
          } else {
            // No redirect result, try popup with timeout
            final provider = GoogleAuthProvider()
              ..addScope('email')
              ..addScope('profile')
              ..addScope('openid');

            provider.setCustomParameters({
              'prompt': 'select_account',
              'access_type': 'online',
            });

            debugPrint('🌐 Attempting popup sign-in with timeout...');

            // Add timeout to prevent infinite loading
            userCred = await FirebaseAuth.instance
                .signInWithPopup(provider)
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    debugPrint('⏰ Popup sign-in timed out, trying redirect...');
                    throw Exception('Popup timeout - will try redirect');
                  },
                );

            final cred = userCred.credential;
            if (cred is OAuthCredential) {
              accessTokenForPeople = cred.accessToken;
            }
            // Wait for auth state to propagate
            final u = await _waitForFirebaseUser();
            if (kDebugMode) {
              debugPrint('👤 Auth state after popup: user=${u?.uid ?? 'null'}');
            }
          }
        } catch (e) {
          debugPrint('🔄 Web popup failed: $e, trying redirect...');

          // Fallback to redirect
          final provider = GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});

          await FirebaseAuth.instance.signInWithRedirect(provider);
          return null; // Will complete on redirect return
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

      // Ensure currentUser is up-to-date after sign-in
      try {
        await userCred.user?.reload();
      } catch (_) {}
      final user = FirebaseAuth.instance.currentUser ?? userCred.user!;

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

      // Firestore handshake (non-blocking):
      // - Do NOT overwrite hasOnboarded on sign-in.
      // - Set hasOnboarded=false only when creating a brand new user document or when the field is missing.
      // - Merge only non-null fields to avoid clobbering existing values with null.
      try {
        final users = FirebaseFirestore.instance.collection('users');
        final docRef = users.doc(user.uid);
        final existing = await docRef.get();
        final Map<String, dynamic> toMerge = {
          'uid': user.uid,
          'email': user.email,
          'provider': 'google',
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
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
      } catch (fsErr) {
        // Don't block login on Firestore write errors
        ErrorHandlingService.instance.handleError(
          fsErr,
          context: 'AuthService: Firestore handshake after Google sign-in',
          showToUser: false,
        );
        return AuthResult(user: user, profile: null);
      }
    } catch (e) {
      // Enhanced error handling with specific diagnostics
      debugPrint('🔥 Google Sign-In Error Details:');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');

      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Exception:');
        debugPrint('  Code: ${e.code}');
        debugPrint('  Message: ${e.message}');
        debugPrint('  Details: ${e.toString()}');

        // Handle specific Firebase Auth errors
        switch (e.code) {
          case 'internal-error':
            // Log additional context for internal errors
            debugPrint('🔍 Internal Error Details:');
            debugPrint(
              '  Auth Domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}',
            );
            debugPrint(
              '  Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}',
            );
            debugPrint(
              '  Current URL: ${kIsWeb ? "web environment" : "mobile environment"}',
            );

            // Try one more time with a clean initialization
            if (kIsWeb) {
              debugPrint('🔄 Attempting recovery with clean initialization...');
              try {
                // Clear any existing auth state
                await FirebaseAuth.instance.signOut();

                // Wait and retry with minimal provider setup
                await Future.delayed(const Duration(seconds: 1));

                final provider = GoogleAuthProvider();
                await FirebaseAuth.instance.signInWithRedirect(provider);
                return null; // Will complete on redirect
              } catch (retryError) {
                debugPrint('🚨 Recovery attempt failed: $retryError');
              }
            }

            throw Exception(
              'Google Sign-In Configuration Error\n\n'
              '🚨 VERIFICATION CHECKLIST:\n\n'
              '1. Google Cloud Console OAuth Client:\n'
              '   https://console.cloud.google.com/apis/credentials?project=${DefaultFirebaseOptions.currentPlatform.projectId}\n'
              '   ✓ JavaScript origins: http://localhost:8080, http://127.0.0.1:8080\n'
              '   ✓ Redirect URI: https://${DefaultFirebaseOptions.currentPlatform.authDomain}/__/auth/handler\n\n'
              '2. Firebase Console Settings:\n'
              '   https://console.firebase.google.com/project/${DefaultFirebaseOptions.currentPlatform.projectId}/authentication/providers\n'
              '   ✓ Google provider enabled\n'
              '   ✓ Web SDK configuration correct\n\n'
              '3. Advanced Troubleshooting:\n'
              '   ✓ Clear browser cache and cookies\n'
              '   ✓ Try incognito/private browsing mode\n'
              '   ✓ Check browser console for additional errors\n'
              '   ✓ Verify no browser extensions blocking OAuth\n\n'
              'If all above are correct, the issue may be:\n'
              '• OAuth client not properly linked to Firebase project\n'
              '• API restrictions on the Firebase API key\n'
              '• Browser security policies blocking authentication\n\n'
              'Project: ${DefaultFirebaseOptions.currentPlatform.projectId}\n'
              'Auth Domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}',
            );
          case 'unauthorized-domain':
            throw Exception(
              'Domain not authorized. Add your domain (localhost, 127.0.0.1) to Firebase Auth → Settings → Authorized domains.',
            );
          case 'invalid-api-key':
            throw Exception(
              'Invalid Firebase API key. Please check your firebase_options.dart configuration.',
            );
          case 'api-key-not-valid':
            throw Exception(
              'Firebase API key not valid for this operation. Check Firebase Console settings.',
            );
          default:
            throw Exception('Firebase Auth error (${e.code}): ${e.message}');
        }
      }

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
      if (msg.contains('popup-blocked') || msg.contains('Popup timeout')) {
        throw Exception(
          'Popup blocked or timed out. The app will now try redirect-based sign-in. Please wait to be redirected to Google.',
        );
      }
      if (msg.contains('network') || msg.contains('offline')) {
        throw Exception(
          'Network error during sign-in. Please check your internet connection and try again.',
        );
      }
      if (msg.contains('timeout') || msg.contains('loading')) {
        throw Exception(
          'Sign-in process timed out. This might be due to popup blockers or slow network. Try clearing browser cache or using incognito mode.',
        );
      }

      // Generic fallback with helpful debugging info
      throw Exception(
        'Google Sign-In failed. Error: $e\n'
        'For debugging:\n'
        '1. Check browser console for detailed errors\n'
        '2. Verify Firebase configuration\n'
        '3. Check authorized domains in Firebase Console\n'
        '4. Ensure Google OAuth is properly configured',
      );
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

  /// Links a Google account to an existing email account after provider conflict.
  Future<AuthResult> linkGoogleToExistingAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      // Get Google credential
      UserCredential? googleCred;
      if (kIsWeb) {
        googleCred = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider()
            ..addScope('email')
            ..addScope('profile'),
        );
      } else {
        final googleSignIn = GoogleSignIn(scopes: _scopes);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google sign-in cancelled');

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        googleCred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (googleCred.user == null) {
        throw Exception('Failed to get Google user credential');
      }

      // Link the Google credential to the current user
      final googleOAuthCred = googleCred.credential as OAuthCredential?;
      if (googleOAuthCred == null) {
        throw Exception('Invalid Google credential type');
      }

      final linkedCred = await currentUser.linkWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleOAuthCred.accessToken,
          idToken: googleOAuthCred.idToken,
        ),
      );

      // Update user profile in Firestore
      final users = FirebaseFirestore.instance.collection('users');
      final docRef = users.doc(currentUser.uid);
      await docRef.update({
        'provider': 'linked', // Indicates multiple providers
        'googleLinked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final snap = await docRef.get();
      return AuthResult(user: linkedCred.user!, profile: snap.data());
    } catch (e) {
      debugPrint('Failed to link Google account: $e');
      rethrow;
    }
  }

  /// Migrates data from an existing email account to a Google account.
  /// This is used when "One account per email" policy is enabled.
  Future<AuthResult> migrateEmailAccountToGoogle({
    required String existingEmail,
  }) async {
    try {
      // Find the existing account by email
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: existingEmail)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isEmpty) {
        throw Exception('Existing account not found for email: $existingEmail');
      }

      final existingUserDoc = existingUserQuery.docs.first;
      final existingUid = existingUserDoc.id;
      final existingData = existingUserDoc.data();

      // Sign in with Google to create the new account
      UserCredential? googleCred;
      if (kIsWeb) {
        googleCred = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider()
            ..addScope('email')
            ..addScope('profile'),
        );
      } else {
        final googleSignIn = GoogleSignIn(scopes: _scopes);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google sign-in cancelled');

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        googleCred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (googleCred.user == null) {
        throw Exception('Failed to create Google account');
      }

      final newUid = googleCred.user!.uid;

      // Copy data from old account to new account
      final newUserData = {
        ...existingData,
        'provider': 'google',
        'googleLinked': true,
        'migratedFrom': existingUid,
        'migratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove sensitive migration data
      newUserData.remove('migrationPending');
      newUserData.remove('migrationToken');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUid)
          .set(newUserData);

      // Mark old account as migrated (don't delete immediately for safety)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(existingUid)
          .update({
            'migratedTo': newUid,
            'migratedAt': FieldValue.serverTimestamp(),
            'accountStatus': 'migrated',
          });

      final newUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(newUid)
          .get();

      return AuthResult(user: googleCred.user!, profile: newUserDoc.data());
    } catch (e) {
      debugPrint('Failed to migrate email account to Google: $e');
      rethrow;
    }
  }

  /// Gets information about existing account for a given email.
  Future<Map<String, dynamic>?> getExistingAccountInfo(String email) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final query = await users.where('email', isEqualTo: email).limit(1).get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      return {
        'uid': doc.id,
        'provider': doc.data()['provider'] ?? 'unknown',
        'hasOnboarded': doc.data()['hasOnboarded'] ?? false,
        ...doc.data(),
      };
    } catch (e) {
      debugPrint('Failed to get existing account info: $e');
      return null;
    }
  }

  /// Rollback provider migration within a short time window.
  /// This allows users to undo account linking or migration if they change their mind.
  Future<void> rollbackProviderMigration({
    required String userId,
    required String previousProvider,
    Duration undoWindow = const Duration(seconds: 30),
  }) async {
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final docRef = users.doc(userId);

      // Check if we're within the undo window
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final data = doc.data()!;
      final updatedAt = data['updatedAt'] as Timestamp?;
      if (updatedAt == null) {
        throw Exception('No update timestamp found');
      }

      final timeSinceUpdate = DateTime.now().difference(updatedAt.toDate());
      if (timeSinceUpdate > undoWindow) {
        throw Exception('Undo window has expired (${undoWindow.inSeconds}s)');
      }

      // Rollback the provider change
      await docRef.update({
        'provider': previousProvider,
        'googleLinked': previousProvider == 'linked' ? true : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Successfully rolled back provider migration for user $userId',
      );
    } catch (e) {
      debugPrint('Failed to rollback provider migration: $e');
      rethrow;
    }
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
