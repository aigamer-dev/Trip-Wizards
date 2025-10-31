import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travel_wizards/src/shared/utils/base_controller.dart';

/// Result of authentication operations
enum AuthOutcome { success, failed, needsMigration }

/// Authentication controller using the new Provider-based state management
///
/// This controller manages user authentication state and provides methods
/// for sign in, sign out, and user registration. It replaces the previous
/// singleton-based approach with a proper Provider pattern.
class AuthController extends BaseController {
  static final AuthController _instance = AuthController._internal();

  factory AuthController() => _instance;

  AuthController._internal();

  static AuthController get instance => _instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _currentUser;
  bool _isEmailVerified = false;
  AuthCredential? _pendingCredential;

  /// Current authenticated user
  User? get currentUser => _currentUser;

  /// Whether the user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// User's email address (if available)
  String? get userEmail => _currentUser?.email;

  /// User's display name (if available)
  String? get displayName => _currentUser?.displayName;

  /// User's photo URL (if available)
  String? get photoUrl => _currentUser?.photoURL;

  /// User's unique ID
  String? get userId => _currentUser?.uid;

  /// Whether the user's email is verified
  bool get isEmailVerified => _isEmailVerified;

  /// Whether the user is anonymous
  bool get isAnonymous => _currentUser?.isAnonymous ?? false;

  /// Email address associated with pending migration
  String? get pendingMigrationEmail => _currentUser?.email;

  @override
  void init() {
    super.init();
    _listenToAuthChanges();
    _initializeCurrentUser();
  }

  /// Initialize with current user state
  void _initializeCurrentUser() {
    _currentUser = _firebaseAuth.currentUser;
    _updateEmailVerificationStatus();
    notifyListeners();
  }

  /// Listen to Firebase auth state changes
  void _listenToAuthChanges() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (!isDisposed) {
        _currentUser = user;
        _updateEmailVerificationStatus();
        notifyListeners();
      }
    });
  }

  /// Update email verification status
  void _updateEmailVerificationStatus() {
    _isEmailVerified = _currentUser?.emailVerified ?? false;
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    return await handleAsync(() async {
          final credential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

          _currentUser = credential.user;
          _updateEmailVerificationStatus();

          return _currentUser != null;
        }, context: 'Email Sign In') ??
        false;
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    return await handleAsync(() async {
          final credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

          _currentUser = credential.user;

          // Update display name if provided
          if (displayName != null && displayName.isNotEmpty) {
            await _currentUser?.updateDisplayName(displayName.trim());
            await _currentUser?.reload();
            _currentUser = _firebaseAuth.currentUser;
          }

          _updateEmailVerificationStatus();

          return _currentUser != null;
        }, context: 'Email Sign Up') ??
        false;
  }

  /// Sign in with Google (requires additional setup)
  Future<AuthOutcome> signInWithGoogle() async {
    return await handleAsync(
      () async {
        if (kIsWeb) {
          final provider = GoogleAuthProvider();
          try {
            final credential = await _firebaseAuth.signInWithPopup(provider);
            _currentUser = credential.user;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'account-exists-with-different-credential') {
              _pendingCredential = e.credential;
              return AuthOutcome.needsMigration;
            }
            rethrow;
          }
        } else {
          final googleSignIn = GoogleSignIn();
          final googleUser = await googleSignIn.signIn();

          if (googleUser == null) {
            setError('Google sign-in canceled');
            return AuthOutcome.failed;
          }

          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          try {
            final userCredential = await _firebaseAuth.signInWithCredential(
              credential,
            );
            _currentUser = userCredential.user;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'account-exists-with-different-credential') {
              _pendingCredential = credential;
              return AuthOutcome.needsMigration;
            }
            rethrow;
          }
        }

        if (_currentUser == null) {
          setError('Unable to sign in with Google');
          return AuthOutcome.failed;
        }

        _updateEmailVerificationStatus();
        return AuthOutcome.success;
      },
      context: 'Google Sign In',
    ).then((result) => result ?? AuthOutcome.failed);
  }

  /// Complete provider migration by linking Google account to existing email/password account
  Future<bool> completeProviderMigration(String email, String password) async {
    if (_pendingCredential == null) {
      setError('No pending migration credential available');
      return false;
    }

    return await handleAsync(() async {
          // First sign in with email/password
          final emailCredential = await _firebaseAuth
              .signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );

          _currentUser = emailCredential.user;

          // Then link the Google credential
          await _currentUser!.linkWithCredential(_pendingCredential!);

          // Clear the pending credential
          _pendingCredential = null;

          _updateEmailVerificationStatus();
          return true;
        }, context: 'Provider Migration') ??
        false;
  }

  /// Check if there's a pending migration
  bool get hasPendingMigration => _pendingCredential != null;

  /// Sign out
  Future<bool> signOut() async {
    return await handleAsync(() async {
          await _firebaseAuth.signOut();
          _currentUser = null;
          _isEmailVerified = false;

          return true;
        }, context: 'Sign Out') ??
        false;
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    if (_isEmailVerified) {
      setError('Email is already verified');
      return false;
    }

    return await handleAsync(() async {
          await _currentUser!.sendEmailVerification();
          return true;
        }, context: 'Send Email Verification') ??
        false;
  }

  /// Reload user data to check for email verification
  Future<bool> reloadUser() async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    return await handleAsync(() async {
          await _currentUser!.reload();
          _currentUser = _firebaseAuth.currentUser;
          _updateEmailVerificationStatus();

          return true;
        }, context: 'Reload User') ??
        false;
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return await handleAsync(() async {
          await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
          return true;
        }, context: 'Password Reset') ??
        false;
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    return await handleAsync(() async {
          if (displayName != null) {
            await _currentUser!.updateDisplayName(displayName.trim());
          }

          if (photoURL != null) {
            await _currentUser!.updatePhotoURL(photoURL.trim());
          }

          await _currentUser!.reload();
          _currentUser = _firebaseAuth.currentUser;

          return true;
        }, context: 'Update Profile') ??
        false;
  }

  /// Update user email
  Future<bool> updateEmail(String newEmail) async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    return await handleAsync(() async {
          await _currentUser!.verifyBeforeUpdateEmail(newEmail.trim());
          await _currentUser!.reload();
          _currentUser = _firebaseAuth.currentUser;
          _updateEmailVerificationStatus();

          return true;
        }, context: 'Update Email') ??
        false;
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    return await handleAsync(() async {
          await _currentUser!.updatePassword(newPassword);
          return true;
        }, context: 'Update Password') ??
        false;
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticate(String password) async {
    if (_currentUser == null || _currentUser!.email == null) {
      setError('No user is currently signed in or email not available');
      return false;
    }

    return await handleAsync(() async {
          final credential = EmailAuthProvider.credential(
            email: _currentUser!.email!,
            password: password,
          );

          await _currentUser!.reauthenticateWithCredential(credential);
          return true;
        }, context: 'Re-authenticate') ??
        false;
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (_currentUser == null) {
      setError('No user is currently signed in');
      return false;
    }

    return await handleAsync(() async {
          await _currentUser!.delete();
          _currentUser = null;
          _isEmailVerified = false;

          return true;
        }, context: 'Delete Account') ??
        false;
  }

  /// Check if email is valid format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if password meets requirements
  bool isValidPassword(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Get password requirements text
  String get passwordRequirements =>
      'Password must be at least 8 characters long and contain uppercase, lowercase, and number characters.';

  @override
  void dispose() {
    // Firebase auth stream is automatically disposed
    super.dispose();
  }
}
