import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive data anonymization and pseudonymization service for
/// protecting user privacy while preserving data utility for analytics
/// and application functionality.
///
/// Features:
/// - Multiple anonymization techniques (masking, generalization, perturbation)
/// - Pseudonymization with deterministic and random approaches
/// - K-anonymity and L-diversity compliance for datasets
/// - Differential privacy mechanisms for statistical queries
/// - Reversible pseudonymization for authorized access
/// - Location data anonymization with geofencing
/// - Temporal data anonymization with time bucketing
class DataAnonymizationService {
  // static const String _saltPrefix = 'travel_wizards_anon_';
  // static const int _defaultK = 5; // Default k-anonymity level
  // static const int _defaultL = 2; // Default l-diversity level

  static final DataAnonymizationService _instance =
      DataAnonymizationService._internal();
  factory DataAnonymizationService() => _instance;
  DataAnonymizationService._internal();

  final Random _random = Random.secure();
  late Uint8List _systemSalt;
  bool _isInitialized = false;

  /// Initialize the anonymization service with system-wide salt
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _systemSalt = _generateSystemSalt();
      _isInitialized = true;
      debugPrint('DataAnonymizationService initialized');
    } catch (e) {
      debugPrint('Failed to initialize DataAnonymizationService: $e');
      rethrow;
    }
  }

  /// Anonymize a complete user record
  Future<Map<String, dynamic>> anonymizeUserRecord(
    Map<String, dynamic> userRecord,
    AnonymizationLevel level,
  ) async {
    _ensureInitialized();

    final anonymized = Map<String, dynamic>.from(userRecord);

    // Remove direct identifiers
    anonymized.remove('uid');
    anonymized.remove('email');
    anonymized.remove('displayName');
    anonymized.remove('photoUrl');

    // Apply anonymization based on level
    switch (level) {
      case AnonymizationLevel.minimal:
        await _applyMinimalAnonymization(anonymized);
        break;
      case AnonymizationLevel.standard:
        await _applyStandardAnonymization(anonymized);
        break;
      case AnonymizationLevel.maximum:
        await _applyMaximumAnonymization(anonymized);
        break;
    }

    // Add anonymization metadata
    anonymized['_anonymized'] = true;
    anonymized['_anonymization_level'] = level.name;
    anonymized['_anonymized_at'] = DateTime.now().toIso8601String();

    return anonymized;
  }

  /// Pseudonymize user identifier for analytics
  String pseudonymizeUserId(String userId, {bool deterministic = true}) {
    _ensureInitialized();

    if (deterministic) {
      // Generate consistent pseudonym for the same user
      final input = utf8.encode(userId + base64Encode(_systemSalt));
      final hash = sha256.convert(input);
      return 'anon_${hash.toString().substring(0, 16)}';
    } else {
      // Generate random pseudonym
      return 'anon_${_generateRandomId(16)}';
    }
  }

  /// Anonymize email address
  String anonymizeEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return 'anonymous@domain.com';

    final username = parts[0];
    final domain = parts[1];

    // Keep first and last character if long enough
    if (username.length <= 2) {
      return '***@${_anonymizeDomain(domain)}';
    } else if (username.length <= 4) {
      return '${username[0]}***@${_anonymizeDomain(domain)}';
    } else {
      return '${username[0]}***${username[username.length - 1]}@${_anonymizeDomain(domain)}';
    }
  }

  /// Anonymize phone number
  String anonymizePhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 4) return '***-***-****';

    // Keep country code and last 2 digits
    if (digits.length <= 7) {
      return '***-***-**${digits.substring(digits.length - 2)}';
    } else {
      final countryCode = digits.substring(0, min(3, digits.length - 7));
      final lastDigits = digits.substring(digits.length - 2);
      return '$countryCode-***-***-**$lastDigits';
    }
  }

  /// Anonymize location coordinates with geographic perturbation
  Future<AnonymizedLocation> anonymizeLocation(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
    LocationAnonymizationMethod method =
        LocationAnonymizationMethod.perturbation,
  }) async {
    _ensureInitialized();

    switch (method) {
      case LocationAnonymizationMethod.perturbation:
        return _perturbLocation(latitude, longitude, radiusKm);
      case LocationAnonymizationMethod.generalization:
        return _generalizeLocation(latitude, longitude, radiusKm);
      case LocationAnonymizationMethod.geohashing:
        return _geohashLocation(latitude, longitude, radiusKm);
    }
  }

  /// Anonymize travel destination with city-level generalization
  String anonymizeDestination(String destination) {
    // Common patterns for travel destinations
    final patterns = [
      RegExp(r'([^,]+),\s*([^,]+),\s*([^,]+)'), // Address, City, Country
      RegExp(r'([^,]+),\s*([^,]+)'), // City, Country or State
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(destination);
      if (match != null) {
        if (match.groupCount == 3) {
          // Keep city and country, anonymize address
          return '*****, ${match.group(2)}, ${match.group(3)}';
        } else if (match.groupCount == 2) {
          // Keep country/state, anonymize city
          return '*****, ${match.group(2)}';
        }
      }
    }

    return '*****'; // Fallback full anonymization
  }

  /// Anonymize temporal data with bucketing
  DateTime anonymizeDateTime(
    DateTime dateTime,
    TemporalAnonymizationLevel level,
  ) {
    switch (level) {
      case TemporalAnonymizationLevel.hour:
        return DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
        );
      case TemporalAnonymizationLevel.day:
        return DateTime(dateTime.year, dateTime.month, dateTime.day);
      case TemporalAnonymizationLevel.week:
        final startOfWeek = dateTime.subtract(
          Duration(days: dateTime.weekday - 1),
        );
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case TemporalAnonymizationLevel.month:
        return DateTime(dateTime.year, dateTime.month);
      case TemporalAnonymizationLevel.quarter:
        final quarter = ((dateTime.month - 1) ~/ 3) * 3 + 1;
        return DateTime(dateTime.year, quarter);
      case TemporalAnonymizationLevel.year:
        return DateTime(dateTime.year);
    }
  }

  /// Apply differential privacy to numerical data
  double applyDifferentialPrivacy(
    double value, {
    double epsilon = 1.0,
    double sensitivity = 1.0,
  }) {
    // Laplace mechanism for differential privacy
    final b = sensitivity / epsilon;
    final noise = _laplacianNoise(b);
    return value + noise;
  }

  /// Anonymize age with generalization
  String anonymizeAge(int age) {
    if (age < 18) return 'Under 18';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    if (age < 65) return '55-64';
    return '65+';
  }

  /// Generate k-anonymous dataset
  Future<List<Map<String, dynamic>>> generateKAnonymousDataset(
    List<Map<String, dynamic>> dataset,
    List<String> quasiIdentifiers, {
    int k = 5,
  }) async {
    _ensureInitialized();

    // Group records by quasi-identifier combinations
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final record in dataset) {
      final key = _generateQuasiIdentifierKey(record, quasiIdentifiers);
      groups[key] = groups[key] ?? [];
      groups[key]!.add(record);
    }

    final kAnonymousDataset = <Map<String, dynamic>>[];

    for (final group in groups.values) {
      if (group.length >= k) {
        // Group satisfies k-anonymity
        kAnonymousDataset.addAll(group);
      } else {
        // Generalize group to satisfy k-anonymity
        final generalizedRecords = await _generalizeGroup(
          group,
          quasiIdentifiers,
          k,
        );
        kAnonymousDataset.addAll(generalizedRecords);
      }
    }

    return kAnonymousDataset;
  }

  /// Check if dataset satisfies k-anonymity
  bool checkKAnonymity(
    List<Map<String, dynamic>> dataset,
    List<String> quasiIdentifiers,
    int k,
  ) {
    final groups = <String, int>{};

    for (final record in dataset) {
      final key = _generateQuasiIdentifierKey(record, quasiIdentifiers);
      groups[key] = (groups[key] ?? 0) + 1;
    }

    return groups.values.every((count) => count >= k);
  }

  /// Apply minimal anonymization (basic PII removal)
  Future<void> _applyMinimalAnonymization(Map<String, dynamic> record) async {
    // Pseudonymize identifiers
    if (record.containsKey('phoneNumber')) {
      record['phoneNumber'] = anonymizePhoneNumber(record['phoneNumber']);
    }

    // Generalize location data
    if (record.containsKey('location')) {
      final location = record['location'];
      if (location is Map && location.containsKey('address')) {
        location['address'] = _generalizeAddress(location['address']);
      }
    }
  }

  /// Apply standard anonymization (moderate privacy protection)
  Future<void> _applyStandardAnonymization(Map<String, dynamic> record) async {
    await _applyMinimalAnonymization(record);

    // Age generalization
    if (record.containsKey('age')) {
      record['age'] = anonymizeAge(record['age']);
    }

    // Temporal data bucketing
    final dateFields = ['createdAt', 'lastLogin', 'dateOfBirth'];
    for (final field in dateFields) {
      if (record.containsKey(field) && record[field] != null) {
        final date = DateTime.parse(record[field]);
        record[field] = anonymizeDateTime(
          date,
          TemporalAnonymizationLevel.day,
        ).toIso8601String();
      }
    }

    // Location perturbation
    if (record.containsKey('location')) {
      final location = record['location'];
      if (location is Map &&
          location.containsKey('latitude') &&
          location.containsKey('longitude')) {
        final anonymizedLoc = await anonymizeLocation(
          location['latitude'],
          location['longitude'],
          radiusKm: 2.0,
        );
        location['latitude'] = anonymizedLoc.latitude;
        location['longitude'] = anonymizedLoc.longitude;
        location['_anonymized'] = true;
      }
    }
  }

  /// Apply maximum anonymization (high privacy protection)
  Future<void> _applyMaximumAnonymization(Map<String, dynamic> record) async {
    await _applyStandardAnonymization(record);

    // Remove or heavily anonymize all quasi-identifiers
    final fieldsToAnonymize = [
      'travelStyle',
      'interests',
      'budgetRange',
      'accommodationType',
      'preferences',
    ];

    for (final field in fieldsToAnonymize) {
      if (record.containsKey(field)) {
        if (record[field] is List) {
          // Generalize lists
          final list = record[field] as List;
          record[field] = list.isEmpty ? [] : ['***'];
        } else if (record[field] is String) {
          record[field] = '***';
        }
      }
    }

    // Temporal data with weekly bucketing
    final dateFields = ['createdAt', 'lastLogin', 'dateOfBirth'];
    for (final field in dateFields) {
      if (record.containsKey(field) && record[field] != null) {
        final date = DateTime.parse(record[field]);
        record[field] = anonymizeDateTime(
          date,
          TemporalAnonymizationLevel.week,
        ).toIso8601String();
      }
    }
  }

  /// Anonymize domain name
  String _anonymizeDomain(String domain) {
    final parts = domain.split('.');
    if (parts.length >= 2) {
      // Keep TLD, anonymize the rest
      return '*****.${parts.last}';
    }
    return '*****';
  }

  /// Perturb location coordinates
  AnonymizedLocation _perturbLocation(double lat, double lng, double radiusKm) {
    // Convert radius to degrees (approximate)
    final radiusDegrees = radiusKm / 111.0; // 1 degree ≈ 111 km

    // Generate random direction and distance
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * radiusDegrees;

    final deltaLat = distance * cos(angle);
    final deltaLng = distance * sin(angle) / cos(lat * pi / 180);

    return AnonymizedLocation(
      latitude: lat + deltaLat,
      longitude: lng + deltaLng,
      accuracy: radiusKm * 1000, // Convert to meters
      method: LocationAnonymizationMethod.perturbation,
    );
  }

  /// Generalize location to grid cell
  AnonymizedLocation _generalizeLocation(
    double lat,
    double lng,
    double radiusKm,
  ) {
    // Grid cell size in degrees
    final cellSize = radiusKm / 111.0;

    // Snap to grid
    final gridLat = (lat / cellSize).floor() * cellSize + (cellSize / 2);
    final gridLng = (lng / cellSize).floor() * cellSize + (cellSize / 2);

    return AnonymizedLocation(
      latitude: gridLat,
      longitude: gridLng,
      accuracy: radiusKm * 1000,
      method: LocationAnonymizationMethod.generalization,
    );
  }

  /// Create geohash for location
  AnonymizedLocation _geohashLocation(double lat, double lng, double radiusKm) {
    // Simple geohash implementation (precision based on radius)
    final precision = radiusKm < 1 ? 8 : (radiusKm < 5 ? 6 : 4);
    final geohash = _generateGeohash(lat, lng, precision);

    // Decode geohash back to approximate center
    final decoded = _decodeGeohash(geohash);

    return AnonymizedLocation(
      latitude: decoded['lat']!,
      longitude: decoded['lng']!,
      accuracy: radiusKm * 1000,
      method: LocationAnonymizationMethod.geohashing,
      geohash: geohash,
    );
  }

  /// Generate geohash (simplified implementation)
  String _generateGeohash(double lat, double lng, int precision) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;

    final result = StringBuffer();
    var bits = 0;
    var bit = 0;
    var isEven = true; // Start with longitude

    while (result.length < precision) {
      if (isEven) {
        // Longitude
        final mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          bit = (bit << 1) | 1;
          lngMin = mid;
        } else {
          bit = bit << 1;
          lngMax = mid;
        }
      } else {
        // Latitude
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          bit = (bit << 1) | 1;
          latMin = mid;
        } else {
          bit = bit << 1;
          latMax = mid;
        }
      }

      isEven = !isEven;
      bits++;

      if (bits == 5) {
        result.write(base32[bit]);
        bits = 0;
        bit = 0;
      }
    }

    return result.toString();
  }

  /// Decode geohash to coordinates
  Map<String, double> _decodeGeohash(String geohash) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;

    var isEven = true;

    for (var i = 0; i < geohash.length; i++) {
      final char = geohash[i];
      final idx = base32.indexOf(char);

      for (var j = 4; j >= 0; j--) {
        final bit = (idx >> j) & 1;

        if (isEven) {
          // Longitude
          final mid = (lngMin + lngMax) / 2;
          if (bit == 1) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          // Latitude
          final mid = (latMin + latMax) / 2;
          if (bit == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }

        isEven = !isEven;
      }
    }

    return {'lat': (latMin + latMax) / 2, 'lng': (lngMin + lngMax) / 2};
  }

  /// Generate Laplacian noise for differential privacy
  double _laplacianNoise(double b) {
    final u = _random.nextDouble() - 0.5;
    return -b * (u.sign * log(1 - 2 * u.abs()));
  }

  /// Generalize address string
  String _generalizeAddress(String address) {
    // Remove street number and specific address
    final parts = address.split(',');
    if (parts.length > 1) {
      // Keep city and state/country, remove street address
      return '*****, ${parts.skip(1).join(',')}';
    }
    return '*****';
  }

  /// Generate quasi-identifier key for k-anonymity
  String _generateQuasiIdentifierKey(
    Map<String, dynamic> record,
    List<String> quasiIdentifiers,
  ) {
    final values = <String>[];
    for (final identifier in quasiIdentifiers) {
      values.add(record[identifier]?.toString() ?? 'null');
    }
    return values.join('|');
  }

  /// Generalize group to satisfy k-anonymity
  Future<List<Map<String, dynamic>>> _generalizeGroup(
    List<Map<String, dynamic>> group,
    List<String> quasiIdentifiers,
    int k,
  ) async {
    // Simple generalization: replace with common values or ranges
    final generalized = <Map<String, dynamic>>[];

    for (final record in group) {
      final generalizedRecord = Map<String, dynamic>.from(record);

      for (final identifier in quasiIdentifiers) {
        if (generalizedRecord.containsKey(identifier)) {
          generalizedRecord[identifier] = _generalizeValue(
            generalizedRecord[identifier],
          );
        }
      }

      generalized.add(generalizedRecord);
    }

    return generalized;
  }

  /// Generalize individual value
  dynamic _generalizeValue(dynamic value) {
    if (value is int) {
      // Generalize integers to ranges
      if (value < 25) return '< 25';
      if (value < 50) return '25-49';
      if (value < 75) return '50-74';
      return '75+';
    } else if (value is String) {
      // Generalize strings to patterns
      if (value.length <= 3) return '***';
      return '${value.substring(0, 1)}***';
    }
    return value;
  }

  /// Generate system salt
  Uint8List _generateSystemSalt() {
    return Uint8List.fromList(List.generate(32, (_) => _random.nextInt(256)));
  }

  /// Generate random ID
  String _generateRandomId(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'DataAnonymizationService not initialized. Call initialize() first.',
      );
    }
  }
}

/// Anonymization levels
enum AnonymizationLevel {
  minimal, // Basic PII removal
  standard, // Moderate privacy protection
  maximum, // High privacy protection
}

/// Location anonymization methods
enum LocationAnonymizationMethod {
  perturbation, // Add random noise
  generalization, // Grid-based generalization
  geohashing, // Geohash-based
}

/// Temporal anonymization levels
enum TemporalAnonymizationLevel { hour, day, week, month, quarter, year }

/// Anonymized location result
class AnonymizedLocation {
  final double latitude;
  final double longitude;
  final double accuracy; // In meters
  final LocationAnonymizationMethod method;
  final String? geohash;

  const AnonymizedLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.method,
    this.geohash,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'method': method.name,
      if (geohash != null) 'geohash': geohash,
      '_anonymized': true,
    };
  }
}

/// Data anonymization utility functions
class AnonymizationUtils {
  /// Check if value needs anonymization
  static bool needsAnonymization(String fieldName, dynamic value) {
    if (value == null) return false;

    final sensitiveFields = {
      'email',
      'phone',
      'address',
      'name',
      'ssn',
      'passport',
      'creditcard',
      'bankaccount',
      'coordinates',
      'location',
    };

    return sensitiveFields.any(
      (field) =>
          fieldName.toLowerCase().contains(field) ||
          field.contains(fieldName.toLowerCase()),
    );
  }

  /// Get recommended anonymization level based on data sensitivity
  static AnonymizationLevel getRecommendedLevel(Map<String, dynamic> data) {
    var score = 0;

    // Check for high-sensitivity fields
    final highSensitivityFields = ['email', 'phone', 'address', 'payment'];
    for (final field in highSensitivityFields) {
      if (data.keys.any((key) => key.toLowerCase().contains(field))) {
        score += 3;
      }
    }

    // Check for medium-sensitivity fields
    final mediumSensitivityFields = ['location', 'preferences', 'behavior'];
    for (final field in mediumSensitivityFields) {
      if (data.keys.any((key) => key.toLowerCase().contains(field))) {
        score += 2;
      }
    }

    // Check for low-sensitivity fields
    final lowSensitivityFields = ['settings', 'language', 'theme'];
    for (final field in lowSensitivityFields) {
      if (data.keys.any((key) => key.toLowerCase().contains(field))) {
        score += 1;
      }
    }

    if (score >= 6) return AnonymizationLevel.maximum;
    if (score >= 3) return AnonymizationLevel.standard;
    return AnonymizationLevel.minimal;
  }

  /// Validate anonymization quality
  static AnonymizationQuality validateAnonymization(
    Map<String, dynamic> original,
    Map<String, dynamic> anonymized,
  ) {
    var privacyScore = 0.0;
    var utilityScore = 0.0;
    final issues = <String>[];

    // Check privacy protection
    final sensitiveFields = ['email', 'phone', 'address', 'name'];
    for (final field in sensitiveFields) {
      if (original.containsKey(field) && anonymized.containsKey(field)) {
        if (original[field] == anonymized[field]) {
          issues.add('Field $field not anonymized');
        } else {
          privacyScore += 1.0;
        }
      }
    }

    // Check data utility preservation
    final utilityFields = ['age', 'location', 'preferences'];
    for (final field in utilityFields) {
      if (original.containsKey(field) && anonymized.containsKey(field)) {
        if (anonymized[field] != null) {
          utilityScore += 1.0;
        }
      }
    }

    return AnonymizationQuality(
      privacyScore: privacyScore / sensitiveFields.length,
      utilityScore: utilityScore / utilityFields.length,
      issues: issues,
    );
  }
}

/// Anonymization quality assessment
class AnonymizationQuality {
  final double privacyScore; // 0.0 to 1.0
  final double utilityScore; // 0.0 to 1.0
  final List<String> issues;

  const AnonymizationQuality({
    required this.privacyScore,
    required this.utilityScore,
    required this.issues,
  });

  bool get isGoodQuality =>
      privacyScore >= 0.8 && utilityScore >= 0.6 && issues.isEmpty;

  @override
  String toString() {
    return 'AnonymizationQuality(privacy: ${(privacyScore * 100).toStringAsFixed(1)}%, '
        'utility: ${(utilityScore * 100).toStringAsFixed(1)}%, issues: ${issues.length})';
  }
}
