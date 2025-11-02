import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive user consent management system for GDPR/CCPA compliance
/// providing granular permissions for data collection, processing, and sharing
/// with consent tracking, withdrawal mechanisms, and audit trails.
///
/// Features:
/// - Granular consent categories (analytics, personalization, marketing, etc.)
/// - GDPR Article 7 compliant consent (freely given, specific, informed, unambiguous)
/// - Consent versioning and change tracking
/// - Easy withdrawal mechanisms with immediate effect
/// - Audit trail for compliance reporting
/// - Default privacy-first approach (opt-in only)
/// - Integration with data encryption and anonymization services
class UserConsentManagementService {
  static const String _consentStorageKey = 'user_consent_preferences';
  static const String _consentVersionKey = 'consent_version';
  static const int _currentConsentVersion = 1;

  static final UserConsentManagementService _instance =
      UserConsentManagementService._internal();
  factory UserConsentManagementService() => _instance;
  UserConsentManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  ConsentPreferences? _currentConsent;
  bool _isInitialized = false;

  /// Initialize consent management for current user
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConsentPreferences();
      _isInitialized = true;
      debugPrint('UserConsentManagementService initialized');
    } catch (e) {
      debugPrint('Failed to initialize UserConsentManagementService: $e');
      // Initialize with default (minimal) consent
      _currentConsent = ConsentPreferences.defaultMinimal();
      _isInitialized = true;
    }
  }

  /// Get current consent preferences
  ConsentPreferences get currentConsent {
    _ensureInitialized();
    return _currentConsent ?? ConsentPreferences.defaultMinimal();
  }

  /// Check if user has given consent for a specific purpose
  bool hasConsentFor(ConsentCategory category) {
    _ensureInitialized();
    final consent = currentConsent;

    switch (category) {
      case ConsentCategory.essential:
        return true; // Essential always allowed (functional necessity)
      case ConsentCategory.analytics:
        return consent.analyticsConsent;
      case ConsentCategory.personalization:
        return consent.personalizationConsent;
      case ConsentCategory.marketing:
        return consent.marketingConsent;
      case ConsentCategory.locationTracking:
        return consent.locationTrackingConsent;
      case ConsentCategory.dataSharingPartners:
        return consent.dataSharingConsent;
      case ConsentCategory.advertising:
        return consent.advertisingConsent;
      case ConsentCategory.socialMediaIntegration:
        return consent.socialMediaConsent;
      case ConsentCategory.pushNotifications:
        return consent.pushNotificationsConsent;
      case ConsentCategory.crashReporting:
        return consent.crashReportingConsent;
      case ConsentCategory.performanceMonitoring:
        return consent.performanceMonitoringConsent;
    }
  }

  /// Update consent preferences with audit trail
  Future<void> updateConsent(ConsentPreferences newConsent) async {
    _ensureInitialized();

    final previousConsent = _currentConsent;
    _currentConsent = newConsent.copyWith(
      lastUpdated: DateTime.now(),
      version: _currentConsentVersion,
    );

    try {
      // Save locally first
      await _saveConsentLocally(_currentConsent!);

      // Save to Firestore with audit trail
      await _saveConsentToFirestore(_currentConsent!, previousConsent);

      // Log consent change for audit
      await _logConsentChange(previousConsent, _currentConsent!);

      debugPrint('Consent preferences updated successfully');
    } catch (e) {
      debugPrint('Failed to update consent preferences: $e');
      // Revert local changes on failure
      _currentConsent = previousConsent;
      rethrow;
    }
  }

  /// Grant consent for specific category
  Future<void> grantConsent(ConsentCategory category) async {
    final updated = _updateConsentCategory(currentConsent, category, true);
    await updateConsent(updated);
  }

  /// Withdraw consent for specific category
  Future<void> withdrawConsent(ConsentCategory category) async {
    if (category == ConsentCategory.essential) {
      throw ArgumentError('Cannot withdraw essential consent');
    }

    final updated = _updateConsentCategory(currentConsent, category, false);
    await updateConsent(updated);
  }

  /// Grant multiple consents at once
  Future<void> grantMultipleConsents(Set<ConsentCategory> categories) async {
    var updated = currentConsent;
    for (final category in categories) {
      updated = _updateConsentCategory(updated, category, true);
    }
    await updateConsent(updated);
  }

  /// Withdraw multiple consents at once
  Future<void> withdrawMultipleConsents(Set<ConsentCategory> categories) async {
    var updated = currentConsent;
    for (final category in categories) {
      if (category != ConsentCategory.essential) {
        updated = _updateConsentCategory(updated, category, false);
      }
    }
    await updateConsent(updated);
  }

  /// Check if consent needs to be refreshed (version changed, expired, etc.)
  bool needsConsentRefresh() {
    _ensureInitialized();
    final consent = currentConsent;

    // Check version compatibility
    if (consent.version < _currentConsentVersion) {
      return true;
    }

    // Check expiration (consent should be refreshed annually per GDPR)
    final daysSinceUpdate = DateTime.now()
        .difference(consent.lastUpdated)
        .inDays;
    if (daysSinceUpdate > 365) {
      return true;
    }

    // Check if user has never given explicit consent
    if (!consent.hasExplicitConsent) {
      return true;
    }

    return false;
  }

  /// Show consent banner/dialog requirement check
  bool shouldShowConsentPrompt() {
    return !_isInitialized ||
        needsConsentRefresh() ||
        !currentConsent.hasExplicitConsent;
  }

  /// Get consent summary for privacy dashboard
  ConsentSummary getConsentSummary() {
    _ensureInitialized();
    final consent = currentConsent;

    final granted = <ConsentCategory>[];
    final denied = <ConsentCategory>[];

    for (final category in ConsentCategory.values) {
      if (hasConsentFor(category)) {
        granted.add(category);
      } else {
        denied.add(category);
      }
    }

    return ConsentSummary(
      granted: granted,
      denied: denied,
      lastUpdated: consent.lastUpdated,
      version: consent.version,
      hasExplicitConsent: consent.hasExplicitConsent,
      needsRefresh: needsConsentRefresh(),
    );
  }

  /// Get consent history for audit purposes
  Future<List<ConsentAuditEntry>> getConsentHistory({int limit = 50}) async {
    _ensureInitialized();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('consent_audit')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ConsentAuditEntry.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Failed to load consent history: $e');
      return [];
    }
  }

  /// Export consent data for user (GDPR right to data portability)
  Future<Map<String, dynamic>> exportConsentData() async {
    _ensureInitialized();

    final summary = getConsentSummary();
    final history = await getConsentHistory(limit: 100);

    return {
      'current_consent': currentConsent.toJson(),
      'consent_summary': summary.toJson(),
      'consent_history': history.map((e) => e.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'consent_version': _currentConsentVersion,
    };
  }

  /// Delete all consent data (GDPR right to be forgotten)
  Future<void> deleteConsentData() async {
    _ensureInitialized();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete from Firestore
      final batch = _firestore.batch();

      // Delete consent document
      batch.delete(
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('privacy')
            .doc('consent'),
      );

      // Delete audit trail
      final auditQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('consent_audit')
          .get();

      for (final doc in auditQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentStorageKey);
      await prefs.remove(_consentVersionKey);

      // Reset to minimal consent
      _currentConsent = ConsentPreferences.defaultMinimal();

      debugPrint('Consent data deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete consent data: $e');
      rethrow;
    }
  }

  /// Load consent preferences from storage
  Future<void> _loadConsentPreferences() async {
    // Try local storage first (faster)
    final prefs = await SharedPreferences.getInstance();
    final localConsentJson = prefs.getString(_consentStorageKey);

    if (localConsentJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          await compute(_parseJson, localConsentJson),
        );
        _currentConsent = ConsentPreferences.fromJson(json);

        // Validate version compatibility
        if (_currentConsent!.version < _currentConsentVersion) {
          debugPrint('Consent version outdated, will prompt for refresh');
        }
        return;
      } catch (e) {
        debugPrint('Failed to parse local consent data: $e');
      }
    }

    // Fallback to Firestore
    await _loadConsentFromFirestore();
  }

  /// Load consent from Firestore
  Future<void> _loadConsentFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _currentConsent = ConsentPreferences.defaultMinimal();
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('privacy')
          .doc('consent')
          .get();

      if (doc.exists && doc.data() != null) {
        _currentConsent = ConsentPreferences.fromJson(doc.data()!);

        // Also save locally for faster access
        await _saveConsentLocally(_currentConsent!);
      } else {
        _currentConsent = ConsentPreferences.defaultMinimal();
      }
    } catch (e) {
      debugPrint('Failed to load consent from Firestore: $e');
      _currentConsent = ConsentPreferences.defaultMinimal();
    }
  }

  /// Save consent locally
  Future<void> _saveConsentLocally(ConsentPreferences consent) async {
    final prefs = await SharedPreferences.getInstance();
    final json = await compute(_stringifyJson, consent.toJson());
    await prefs.setString(_consentStorageKey, json);
    await prefs.setInt(_consentVersionKey, consent.version);
  }

  /// Save consent to Firestore
  Future<void> _saveConsentToFirestore(
    ConsentPreferences consent,
    ConsentPreferences? previous,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('privacy')
        .doc('consent')
        .set(consent.toJson(), SetOptions(merge: true));
  }

  /// Log consent change for audit trail
  Future<void> _logConsentChange(
    ConsentPreferences? previous,
    ConsentPreferences current,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final changes = <String, dynamic>{};

    if (previous != null) {
      // Track what changed
      final categories = ConsentCategory.values;
      for (final category in categories) {
        final previousValue = _getConsentValueForCategory(previous, category);
        final currentValue = _getConsentValueForCategory(current, category);

        if (previousValue != currentValue) {
          changes[category.name] = {'from': previousValue, 'to': currentValue};
        }
      }
    } else {
      changes['action'] = 'initial_consent';
    }

    final auditEntry = ConsentAuditEntry(
      timestamp: DateTime.now(),
      action: previous == null
          ? ConsentAction.initialConsent
          : ConsentAction.consentUpdated,
      changes: changes,
      version: current.version,
      userAgent: 'TravelWizards/1.0', // Could be more dynamic
      ipAddress: null, // Not easily available in Flutter apps
    );

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('consent_audit')
          .add(auditEntry.toJson());
    } catch (e) {
      debugPrint('Failed to log consent audit entry: $e');
      // Don't throw - audit logging failure shouldn't block consent updates
    }
  }

  /// Update specific consent category
  ConsentPreferences _updateConsentCategory(
    ConsentPreferences current,
    ConsentCategory category,
    bool granted,
  ) {
    switch (category) {
      case ConsentCategory.essential:
        return current; // Essential cannot be changed
      case ConsentCategory.analytics:
        return current.copyWith(analyticsConsent: granted);
      case ConsentCategory.personalization:
        return current.copyWith(personalizationConsent: granted);
      case ConsentCategory.marketing:
        return current.copyWith(marketingConsent: granted);
      case ConsentCategory.locationTracking:
        return current.copyWith(locationTrackingConsent: granted);
      case ConsentCategory.dataSharingPartners:
        return current.copyWith(dataSharingConsent: granted);
      case ConsentCategory.advertising:
        return current.copyWith(advertisingConsent: granted);
      case ConsentCategory.socialMediaIntegration:
        return current.copyWith(socialMediaConsent: granted);
      case ConsentCategory.pushNotifications:
        return current.copyWith(pushNotificationsConsent: granted);
      case ConsentCategory.crashReporting:
        return current.copyWith(crashReportingConsent: granted);
      case ConsentCategory.performanceMonitoring:
        return current.copyWith(performanceMonitoringConsent: granted);
    }
  }

  /// Get consent value for category
  bool _getConsentValueForCategory(
    ConsentPreferences consent,
    ConsentCategory category,
  ) {
    switch (category) {
      case ConsentCategory.essential:
        return true;
      case ConsentCategory.analytics:
        return consent.analyticsConsent;
      case ConsentCategory.personalization:
        return consent.personalizationConsent;
      case ConsentCategory.marketing:
        return consent.marketingConsent;
      case ConsentCategory.locationTracking:
        return consent.locationTrackingConsent;
      case ConsentCategory.dataSharingPartners:
        return consent.dataSharingConsent;
      case ConsentCategory.advertising:
        return consent.advertisingConsent;
      case ConsentCategory.socialMediaIntegration:
        return consent.socialMediaConsent;
      case ConsentCategory.pushNotifications:
        return consent.pushNotificationsConsent;
      case ConsentCategory.crashReporting:
        return consent.crashReportingConsent;
      case ConsentCategory.performanceMonitoring:
        return consent.performanceMonitoringConsent;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'UserConsentManagementService not initialized. Call initialize() first.',
      );
    }
  }

  // JSON parsing helper functions for compute isolation
  static Map<String, dynamic> _parseJson(String json) {
    return Map<String, dynamic>.from(jsonDecode(json));
  }

  static String _stringifyJson(Map<String, dynamic> json) {
    return jsonEncode(json);
  }
}

/// Consent categories following GDPR guidelines
enum ConsentCategory {
  essential, // Always required - functional necessity
  analytics, // Usage analytics and statistics
  personalization, // Personalized content and recommendations
  marketing, // Marketing communications and promotions
  locationTracking, // Location-based services and tracking
  dataSharingPartners, // Sharing data with third-party partners
  advertising, // Targeted advertising and ad personalization
  socialMediaIntegration, // Social media features and integration
  pushNotifications, // Push notifications and alerts
  crashReporting, // Crash reports and error tracking
  performanceMonitoring, // Performance monitoring and optimization
}

/// Consent action types for audit trail
enum ConsentAction {
  initialConsent,
  consentGranted,
  consentWithdrawn,
  consentUpdated,
  consentExpired,
  consentDeleted,
}

/// User consent preferences model
class ConsentPreferences {
  final bool analyticsConsent;
  final bool personalizationConsent;
  final bool marketingConsent;
  final bool locationTrackingConsent;
  final bool dataSharingConsent;
  final bool advertisingConsent;
  final bool socialMediaConsent;
  final bool pushNotificationsConsent;
  final bool crashReportingConsent;
  final bool performanceMonitoringConsent;
  final DateTime lastUpdated;
  final int version;
  final bool hasExplicitConsent;

  const ConsentPreferences({
    required this.analyticsConsent,
    required this.personalizationConsent,
    required this.marketingConsent,
    required this.locationTrackingConsent,
    required this.dataSharingConsent,
    required this.advertisingConsent,
    required this.socialMediaConsent,
    required this.pushNotificationsConsent,
    required this.crashReportingConsent,
    required this.performanceMonitoringConsent,
    required this.lastUpdated,
    required this.version,
    required this.hasExplicitConsent,
  });

  /// Create minimal consent (privacy-first approach)
  factory ConsentPreferences.defaultMinimal() {
    return ConsentPreferences(
      analyticsConsent: false,
      personalizationConsent: false,
      marketingConsent: false,
      locationTrackingConsent: false,
      dataSharingConsent: false,
      advertisingConsent: false,
      socialMediaConsent: false,
      pushNotificationsConsent: false,
      crashReportingConsent: false,
      performanceMonitoringConsent: false,
      lastUpdated: DateTime.now(),
      version: 1,
      hasExplicitConsent: false,
    );
  }

  ConsentPreferences copyWith({
    bool? analyticsConsent,
    bool? personalizationConsent,
    bool? marketingConsent,
    bool? locationTrackingConsent,
    bool? dataSharingConsent,
    bool? advertisingConsent,
    bool? socialMediaConsent,
    bool? pushNotificationsConsent,
    bool? crashReportingConsent,
    bool? performanceMonitoringConsent,
    DateTime? lastUpdated,
    int? version,
    bool? hasExplicitConsent,
  }) {
    return ConsentPreferences(
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      personalizationConsent:
          personalizationConsent ?? this.personalizationConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      locationTrackingConsent:
          locationTrackingConsent ?? this.locationTrackingConsent,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
      advertisingConsent: advertisingConsent ?? this.advertisingConsent,
      socialMediaConsent: socialMediaConsent ?? this.socialMediaConsent,
      pushNotificationsConsent:
          pushNotificationsConsent ?? this.pushNotificationsConsent,
      crashReportingConsent:
          crashReportingConsent ?? this.crashReportingConsent,
      performanceMonitoringConsent:
          performanceMonitoringConsent ?? this.performanceMonitoringConsent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      hasExplicitConsent: hasExplicitConsent ?? this.hasExplicitConsent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analyticsConsent': analyticsConsent,
      'personalizationConsent': personalizationConsent,
      'marketingConsent': marketingConsent,
      'locationTrackingConsent': locationTrackingConsent,
      'dataSharingConsent': dataSharingConsent,
      'advertisingConsent': advertisingConsent,
      'socialMediaConsent': socialMediaConsent,
      'pushNotificationsConsent': pushNotificationsConsent,
      'crashReportingConsent': crashReportingConsent,
      'performanceMonitoringConsent': performanceMonitoringConsent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
      'hasExplicitConsent': hasExplicitConsent,
    };
  }

  factory ConsentPreferences.fromJson(Map<String, dynamic> json) {
    return ConsentPreferences(
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      personalizationConsent: json['personalizationConsent'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      locationTrackingConsent:
          json['locationTrackingConsent'] as bool? ?? false,
      dataSharingConsent: json['dataSharingConsent'] as bool? ?? false,
      advertisingConsent: json['advertisingConsent'] as bool? ?? false,
      socialMediaConsent: json['socialMediaConsent'] as bool? ?? false,
      pushNotificationsConsent:
          json['pushNotificationsConsent'] as bool? ?? false,
      crashReportingConsent: json['crashReportingConsent'] as bool? ?? false,
      performanceMonitoringConsent:
          json['performanceMonitoringConsent'] as bool? ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      version: json['version'] as int? ?? 1,
      hasExplicitConsent: json['hasExplicitConsent'] as bool? ?? false,
    );
  }
}

/// Consent summary for privacy dashboard
class ConsentSummary {
  final List<ConsentCategory> granted;
  final List<ConsentCategory> denied;
  final DateTime lastUpdated;
  final int version;
  final bool hasExplicitConsent;
  final bool needsRefresh;

  const ConsentSummary({
    required this.granted,
    required this.denied,
    required this.lastUpdated,
    required this.version,
    required this.hasExplicitConsent,
    required this.needsRefresh,
  });

  Map<String, dynamic> toJson() {
    return {
      'granted': granted.map((c) => c.name).toList(),
      'denied': denied.map((c) => c.name).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
      'hasExplicitConsent': hasExplicitConsent,
      'needsRefresh': needsRefresh,
    };
  }
}

/// Consent audit trail entry
class ConsentAuditEntry {
  final DateTime timestamp;
  final ConsentAction action;
  final Map<String, dynamic> changes;
  final int version;
  final String userAgent;
  final String? ipAddress;

  const ConsentAuditEntry({
    required this.timestamp,
    required this.action,
    required this.changes,
    required this.version,
    required this.userAgent,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action.name,
      'changes': changes,
      'version': version,
      'userAgent': userAgent,
      if (ipAddress != null) 'ipAddress': ipAddress,
    };
  }

  factory ConsentAuditEntry.fromFirestore(Map<String, dynamic> json) {
    return ConsentAuditEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: ConsentAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => ConsentAction.consentUpdated,
      ),
      changes: Map<String, dynamic>.from(json['changes'] as Map? ?? {}),
      version: json['version'] as int? ?? 1,
      userAgent: json['userAgent'] as String? ?? 'Unknown',
      ipAddress: json['ipAddress'] as String?,
    );
  }
}

/// Helper class for consent category metadata
class ConsentCategoryHelper {
  static const Map<ConsentCategory, ConsentCategoryInfo> _categoryInfo = {
    ConsentCategory.essential: ConsentCategoryInfo(
      title: 'Essential',
      description: 'Required for basic app functionality and security',
      required: true,
      defaultValue: true,
    ),
    ConsentCategory.analytics: ConsentCategoryInfo(
      title: 'Analytics',
      description: 'Help us understand how you use the app to improve it',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.personalization: ConsentCategoryInfo(
      title: 'Personalization',
      description: 'Personalized travel recommendations and content',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.marketing: ConsentCategoryInfo(
      title: 'Marketing',
      description: 'Travel deals, promotions, and marketing communications',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.locationTracking: ConsentCategoryInfo(
      title: 'Location Services',
      description: 'Location-based features and recommendations',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.dataSharingPartners: ConsentCategoryInfo(
      title: 'Partner Data Sharing',
      description:
          'Share data with trusted travel partners for better services',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.advertising: ConsentCategoryInfo(
      title: 'Advertising',
      description: 'Personalized ads and sponsored content',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.socialMediaIntegration: ConsentCategoryInfo(
      title: 'Social Media',
      description: 'Social media features and content sharing',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.pushNotifications: ConsentCategoryInfo(
      title: 'Notifications',
      description: 'Push notifications for trips, deals, and updates',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.crashReporting: ConsentCategoryInfo(
      title: 'Crash Reporting',
      description: 'Automatic crash and error reporting for app stability',
      required: false,
      defaultValue: false,
    ),
    ConsentCategory.performanceMonitoring: ConsentCategoryInfo(
      title: 'Performance Monitoring',
      description: 'App performance monitoring and optimization',
      required: false,
      defaultValue: false,
    ),
  };

  static ConsentCategoryInfo getInfo(ConsentCategory category) {
    return _categoryInfo[category]!;
  }

  static List<ConsentCategory> getRequiredCategories() {
    return _categoryInfo.entries
        .where((entry) => entry.value.required)
        .map((entry) => entry.key)
        .toList();
  }

  static List<ConsentCategory> getOptionalCategories() {
    return _categoryInfo.entries
        .where((entry) => !entry.value.required)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Information about a consent category
class ConsentCategoryInfo {
  final String title;
  final String description;
  final bool required;
  final bool defaultValue;

  const ConsentCategoryInfo({
    required this.title,
    required this.description,
    required this.required,
    required this.defaultValue,
  });
}
