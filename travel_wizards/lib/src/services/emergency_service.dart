import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Comprehensive emergency assistance service for travel safety
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  static EmergencyService get instance => _instance;
  EmergencyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Emergency state
  bool _isInitialized = false;
  final List<EmergencyContact> _emergencyContacts = [];
  final List<EmergencyIncident> _incidents = [];

  // Stream controllers
  final StreamController<List<EmergencyContact>> _contactsController =
      StreamController<List<EmergencyContact>>.broadcast();
  final StreamController<List<EmergencyIncident>> _incidentsController =
      StreamController<List<EmergencyIncident>>.broadcast();
  final StreamController<EmergencyAlert> _alertController =
      StreamController<EmergencyAlert>.broadcast();

  // Getters
  Stream<List<EmergencyContact>> get contactsStream =>
      _contactsController.stream;
  Stream<List<EmergencyIncident>> get incidentsStream =>
      _incidentsController.stream;
  Stream<EmergencyAlert> get alertStream => _alertController.stream;
  List<EmergencyContact> get emergencyContacts =>
      List.unmodifiable(_emergencyContacts);
  List<EmergencyIncident> get incidents => List.unmodifiable(_incidents);
  bool get isInitialized => _isInitialized;

  /// Initialize the emergency service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🆘 Initializing EmergencyService...');

      // Load emergency contacts
      await _loadEmergencyContacts();

      // Load incident history
      await _loadIncidents();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ EmergencyService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize EmergencyService: $e');
      rethrow;
    }
  }

  /// Request necessary permissions for emergency services
  Future<void> _requestPermissions() async {
    try {
      // Request contacts permission
      if (await FlutterContacts.requestPermission()) {
        debugPrint('🆘 Contacts permission granted');
      }

      // Request location permission (high accuracy for emergencies)
      final locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.always ||
          locationPermission == LocationPermission.whileInUse) {
        debugPrint('🆘 Location permission granted for emergencies');
      }
    } catch (e) {
      debugPrint('❌ Failed to request emergency permissions: $e');
    }
  }

  /// Trigger emergency assistance
  Future<EmergencyResult> triggerEmergency({
    required EmergencyType type,
    String? description,
    Position? currentLocation,
    String? tripId,
    bool notifyContacts = true,
    bool contactAuthorities = false,
  }) async {
    try {
      debugPrint('🆘 Triggering emergency assistance: $type');

      // Get current location if not provided
      currentLocation ??= await _getCurrentLocation();

      // Create emergency incident
      final incident = EmergencyIncident(
        id: _generateIncidentId(),
        type: type,
        description: description ?? '',
        timestamp: DateTime.now(),
        location: currentLocation,
        tripId: tripId,
        status: EmergencyStatus.active,
        reportedBy: _auth.currentUser?.uid ?? 'anonymous',
        responseActions: [],
      );

      // Save incident
      await _saveIncident(incident);

      // Send emergency alert
      final alert = EmergencyAlert(
        id: incident.id,
        type: type,
        message: _generateEmergencyMessage(type, description),
        location: currentLocation,
        timestamp: DateTime.now(),
        severity: _getEmergencySeverity(type),
      );

      _alertController.add(alert);

      // Notify emergency contacts
      if (notifyContacts && _emergencyContacts.isNotEmpty) {
        await _notifyEmergencyContacts(incident, alert);
      }

      // Contact local authorities if requested
      if (contactAuthorities) {
        await _contactLocalAuthorities(incident);
      }

      // Store in Firebase for backup and coordination
      await _storeEmergencyInFirebase(incident);

      debugPrint('✅ Emergency assistance triggered successfully');

      return EmergencyResult.success(incident);
    } catch (e) {
      debugPrint('❌ Failed to trigger emergency assistance: $e');
      return EmergencyResult.failure('Failed to trigger emergency: $e');
    }
  }

  /// Add emergency contact
  Future<EmergencyResult> addEmergencyContact(EmergencyContact contact) async {
    try {
      // Validate contact
      if (contact.name.isEmpty || contact.phoneNumber.isEmpty) {
        return EmergencyResult.failure(
          'Contact name and phone number are required',
        );
      }

      // Check for duplicates
      final existingContact = _emergencyContacts
          .cast<EmergencyContact?>()
          .firstWhere(
            (c) => c?.phoneNumber == contact.phoneNumber,
            orElse: () => null,
          );

      if (existingContact != null) {
        return EmergencyResult.failure(
          'Contact with this phone number already exists',
        );
      }

      // Add contact
      _emergencyContacts.add(contact);
      _contactsController.add(List.unmodifiable(_emergencyContacts));

      // Save to storage
      await _saveEmergencyContacts();

      debugPrint('✅ Emergency contact added: ${contact.name}');
      return EmergencyResult.success();
    } catch (e) {
      debugPrint('❌ Failed to add emergency contact: $e');
      return EmergencyResult.failure('Failed to add contact: $e');
    }
  }

  /// Remove emergency contact
  Future<EmergencyResult> removeEmergencyContact(String contactId) async {
    try {
      final index = _emergencyContacts.indexWhere((c) => c.id == contactId);
      if (index == -1) {
        return EmergencyResult.failure('Contact not found');
      }

      final contact = _emergencyContacts.removeAt(index);
      _contactsController.add(List.unmodifiable(_emergencyContacts));

      await _saveEmergencyContacts();

      debugPrint('✅ Emergency contact removed: ${contact.name}');
      return EmergencyResult.success();
    } catch (e) {
      debugPrint('❌ Failed to remove emergency contact: $e');
      return EmergencyResult.failure('Failed to remove contact: $e');
    }
  }

  /// Update emergency contact
  Future<EmergencyResult> updateEmergencyContact(
    EmergencyContact updatedContact,
  ) async {
    try {
      final index = _emergencyContacts.indexWhere(
        (c) => c.id == updatedContact.id,
      );
      if (index == -1) {
        return EmergencyResult.failure('Contact not found');
      }

      _emergencyContacts[index] = updatedContact;
      _contactsController.add(List.unmodifiable(_emergencyContacts));

      await _saveEmergencyContacts();

      debugPrint('✅ Emergency contact updated: ${updatedContact.name}');
      return EmergencyResult.success();
    } catch (e) {
      debugPrint('❌ Failed to update emergency contact: $e');
      return EmergencyResult.failure('Failed to update contact: $e');
    }
  }

  /// Import contacts from device
  Future<List<Contact>> importDeviceContacts() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        throw Exception('Contacts permission denied');
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      return contacts;
    } catch (e) {
      debugPrint('❌ Failed to import device contacts: $e');
      rethrow;
    }
  }

  /// Get local emergency numbers for current location
  Future<List<EmergencyNumber>> getLocalEmergencyNumbers(
    Position position,
  ) async {
    try {
      // This would typically use a geocoding service to determine the country/region
      // and return appropriate emergency numbers. For now, return common ones.

      return [
        const EmergencyNumber(
          country: 'Universal',
          service: 'Emergency Services',
          number: '112',
          description: 'Universal emergency number',
        ),
        const EmergencyNumber(
          country: 'India',
          service: 'Police',
          number: '100',
          description: 'Police emergency',
        ),
        const EmergencyNumber(
          country: 'India',
          service: 'Fire',
          number: '101',
          description: 'Fire emergency',
        ),
        const EmergencyNumber(
          country: 'India',
          service: 'Ambulance',
          number: '102',
          description: 'Medical emergency',
        ),
        const EmergencyNumber(
          country: 'US',
          service: 'Emergency Services',
          number: '911',
          description: 'US emergency services',
        ),
      ];
    } catch (e) {
      debugPrint('❌ Failed to get local emergency numbers: $e');
      return [];
    }
  }

  /// Call emergency number
  Future<bool> callEmergencyNumber(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to call emergency number: $e');
      return false;
    }
  }

  /// Send SOS message
  Future<EmergencyResult> sendSOSMessage({
    Position? location,
    String? customMessage,
    List<String>? specificContacts,
  }) async {
    try {
      location ??= await _getCurrentLocation();

      final sosMessage = customMessage ?? _generateSOSMessage(location);

      // Get contacts to notify
      final contactsToNotify = specificContacts != null
          ? _emergencyContacts
                .where((c) => specificContacts.contains(c.id))
                .toList()
          : _emergencyContacts;

      if (contactsToNotify.isEmpty) {
        return EmergencyResult.failure('No emergency contacts configured');
      }

      // Send SOS messages
      final results = <String, bool>{};
      for (final contact in contactsToNotify) {
        final success = await _sendSOSMessage(contact, sosMessage, location);
        results[contact.id] = success;
      }

      // Create incident record
      final incident = EmergencyIncident(
        id: _generateIncidentId(),
        type: EmergencyType.sos,
        description: 'SOS message sent to ${contactsToNotify.length} contacts',
        timestamp: DateTime.now(),
        location: location,
        status: EmergencyStatus.active,
        reportedBy: _auth.currentUser?.uid ?? 'anonymous',
        responseActions: [
          EmergencyAction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: EmergencyActionType.messageSent,
            description: 'SOS messages sent',
            timestamp: DateTime.now(),
            success: results.values.any((success) => success),
          ),
        ],
      );

      await _saveIncident(incident);

      final successCount = results.values.where((success) => success).length;
      if (successCount > 0) {
        return EmergencyResult.success(incident);
      } else {
        return EmergencyResult.failure('Failed to send SOS messages');
      }
    } catch (e) {
      debugPrint('❌ Failed to send SOS message: $e');
      return EmergencyResult.failure('Failed to send SOS: $e');
    }
  }

  /// Update incident status
  Future<void> updateIncidentStatus(
    String incidentId,
    EmergencyStatus status,
  ) async {
    try {
      final index = _incidents.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        _incidents[index] = _incidents[index].copyWith(status: status);
        _incidentsController.add(List.unmodifiable(_incidents));
        await _saveIncidents();

        // Update in Firebase
        await _firestore
            .collection('emergency_incidents')
            .doc(incidentId)
            .update({
              'status': status.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('❌ Failed to update incident status: $e');
    }
  }

  /// Private helper methods
  Future<Position> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('❌ Failed to get current location: $e');
      // Return a default location if unable to get current position
      return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  String _generateEmergencyMessage(EmergencyType type, String? description) {
    final base =
        'EMERGENCY ALERT: ${type.toString().split('.').last.toUpperCase()}';
    if (description != null && description.isNotEmpty) {
      return '$base - $description';
    }
    return base;
  }

  String _generateSOSMessage(Position? location) {
    final locationText = location != null
        ? 'Location: https://maps.google.com/?q=${location.latitude},${location.longitude}'
        : 'Location: Unable to determine';

    return 'SOS - I need help! $locationText. Please contact me or emergency services.';
  }

  EmergencySeverity _getEmergencySeverity(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
      case EmergencyType.accident:
      case EmergencyType.assault:
        return EmergencySeverity.critical;
      case EmergencyType.theft:
      case EmergencyType.harassment:
      case EmergencyType.stranded:
        return EmergencySeverity.high;
      case EmergencyType.sos:
      case EmergencyType.general:
        return EmergencySeverity.medium;
    }
  }

  Future<void> _notifyEmergencyContacts(
    EmergencyIncident incident,
    EmergencyAlert alert,
  ) async {
    for (final contact in _emergencyContacts) {
      try {
        await _sendEmergencyNotification(contact, incident, alert);
      } catch (e) {
        debugPrint('❌ Failed to notify contact ${contact.name}: $e');
      }
    }
  }

  Future<void> _sendEmergencyNotification(
    EmergencyContact contact,
    EmergencyIncident incident,
    EmergencyAlert alert,
  ) async {
    // This would integrate with SMS service or notification service
    // For now, we'll just log and potentially open SMS app
    debugPrint(
      '🆘 Notifying ${contact.name} about emergency: ${alert.message}',
    );

    if (contact.notifyBySMS) {
      await _sendSMSNotification(contact, alert);
    }

    if (contact.notifyByCall && incident.type == EmergencyType.medical) {
      // Auto-call for medical emergencies if enabled
      await callEmergencyNumber(contact.phoneNumber);
    }
  }

  Future<void> _sendSMSNotification(
    EmergencyContact contact,
    EmergencyAlert alert,
  ) async {
    try {
      final message =
          '${alert.message}${alert.location != null ? ' Location: https://maps.google.com/?q=${alert.location!.latitude},${alert.location!.longitude}' : ''}';

      final uri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('❌ Failed to send SMS notification: $e');
    }
  }

  Future<bool> _sendSOSMessage(
    EmergencyContact contact,
    String message,
    Position? location,
  ) async {
    try {
      final fullMessage = location != null
          ? '$message Location: https://maps.google.com/?q=${location.latitude},${location.longitude}'
          : message;

      final uri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {'body': fullMessage},
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to send SOS message to ${contact.name}: $e');
      return false;
    }
  }

  Future<void> _contactLocalAuthorities(EmergencyIncident incident) async {
    // This would integrate with local emergency services
    // For now, we'll provide guidance to the user
    debugPrint(
      '🆘 Guidance: Contact local emergency services for ${incident.type}',
    );
  }

  Future<void> _storeEmergencyInFirebase(EmergencyIncident incident) async {
    try {
      await _firestore.collection('emergency_incidents').doc(incident.id).set({
        ...incident.toJson(),
        'userId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Failed to store emergency in Firebase: $e');
    }
  }

  Future<void> _saveIncident(EmergencyIncident incident) async {
    _incidents.insert(0, incident);

    // Keep only last 50 incidents
    if (_incidents.length > 50) {
      _incidents.removeRange(50, _incidents.length);
    }

    _incidentsController.add(List.unmodifiable(_incidents));
    await _saveIncidents();
  }

  // Storage methods
  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        final contactsList = json.decode(contactsJson) as List;
        _emergencyContacts.clear();
        _emergencyContacts.addAll(
          contactsList.map((json) => EmergencyContact.fromJson(json)),
        );

        _contactsController.add(List.unmodifiable(_emergencyContacts));
      }
    } catch (e) {
      debugPrint('❌ Failed to load emergency contacts: $e');
    }
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(
        _emergencyContacts.map((c) => c.toJson()).toList(),
      );
      await prefs.setString('emergency_contacts', contactsJson);
    } catch (e) {
      debugPrint('❌ Failed to save emergency contacts: $e');
    }
  }

  Future<void> _loadIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incidentsJson = prefs.getString('emergency_incidents');

      if (incidentsJson != null) {
        final incidentsList = json.decode(incidentsJson) as List;
        _incidents.clear();
        _incidents.addAll(
          incidentsList.map((json) => EmergencyIncident.fromJson(json)),
        );

        _incidentsController.add(List.unmodifiable(_incidents));
      }
    } catch (e) {
      debugPrint('❌ Failed to load emergency incidents: $e');
    }
  }

  Future<void> _saveIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incidentsJson = json.encode(
        _incidents.map((i) => i.toJson()).toList(),
      );
      await prefs.setString('emergency_incidents', incidentsJson);
    } catch (e) {
      debugPrint('❌ Failed to save emergency incidents: $e');
    }
  }

  String _generateIncidentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Dispose resources
  void dispose() {
    _contactsController.close();
    _incidentsController.close();
    _alertController.close();
  }
}

// Data models
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final bool notifyBySMS;
  final bool notifyByCall;
  final String? email;
  final String? notes;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    this.notifyBySMS = true,
    this.notifyByCall = false,
    this.email,
    this.notes,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
      notifyBySMS: json['notifyBySMS'] ?? true,
      notifyByCall: json['notifyByCall'] ?? false,
      email: json['email'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'notifyBySMS': notifyBySMS,
      'notifyByCall': notifyByCall,
      'email': email,
      'notes': notes,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    bool? notifyBySMS,
    bool? notifyByCall,
    String? email,
    String? notes,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notifyBySMS: notifyBySMS ?? this.notifyBySMS,
      notifyByCall: notifyByCall ?? this.notifyByCall,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }
}

class EmergencyIncident {
  final String id;
  final EmergencyType type;
  final String description;
  final DateTime timestamp;
  final Position? location;
  final String? tripId;
  final EmergencyStatus status;
  final String reportedBy;
  final List<EmergencyAction> responseActions;

  const EmergencyIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.location,
    this.tripId,
    required this.status,
    required this.reportedBy,
    required this.responseActions,
  });

  factory EmergencyIncident.fromJson(Map<String, dynamic> json) {
    return EmergencyIncident(
      id: json['id'],
      type: EmergencyType.fromString(json['type']),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] != null
          ? Position(
              latitude: json['location']['latitude'],
              longitude: json['location']['longitude'],
              timestamp: DateTime.parse(json['location']['timestamp']),
              accuracy: json['location']['accuracy'],
              altitude: json['location']['altitude'],
              altitudeAccuracy: json['location']['altitudeAccuracy'],
              heading: json['location']['heading'],
              headingAccuracy: json['location']['headingAccuracy'],
              speed: json['location']['speed'],
              speedAccuracy: json['location']['speedAccuracy'],
            )
          : null,
      tripId: json['tripId'],
      status: EmergencyStatus.fromString(json['status']),
      reportedBy: json['reportedBy'],
      responseActions: (json['responseActions'] as List? ?? [])
          .map((action) => EmergencyAction.fromJson(action))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location != null
          ? {
              'latitude': location!.latitude,
              'longitude': location!.longitude,
              'timestamp': location!.timestamp.toIso8601String(),
              'accuracy': location!.accuracy,
              'altitude': location!.altitude,
              'altitudeAccuracy': location!.altitudeAccuracy,
              'heading': location!.heading,
              'headingAccuracy': location!.headingAccuracy,
              'speed': location!.speed,
              'speedAccuracy': location!.speedAccuracy,
            }
          : null,
      'tripId': tripId,
      'status': status.toString(),
      'reportedBy': reportedBy,
      'responseActions': responseActions
          .map((action) => action.toJson())
          .toList(),
    };
  }

  EmergencyIncident copyWith({
    String? id,
    EmergencyType? type,
    String? description,
    DateTime? timestamp,
    Position? location,
    String? tripId,
    EmergencyStatus? status,
    String? reportedBy,
    List<EmergencyAction>? responseActions,
  }) {
    return EmergencyIncident(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      responseActions: responseActions ?? this.responseActions,
    );
  }
}

class EmergencyAction {
  final String id;
  final EmergencyActionType type;
  final String description;
  final DateTime timestamp;
  final bool success;

  const EmergencyAction({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.success,
  });

  factory EmergencyAction.fromJson(Map<String, dynamic> json) {
    return EmergencyAction(
      id: json['id'],
      type: EmergencyActionType.fromString(json['type']),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
    };
  }
}

class EmergencyAlert {
  final String id;
  final EmergencyType type;
  final String message;
  final Position? location;
  final DateTime timestamp;
  final EmergencySeverity severity;

  const EmergencyAlert({
    required this.id,
    required this.type,
    required this.message,
    this.location,
    required this.timestamp,
    required this.severity,
  });
}

class EmergencyNumber {
  final String country;
  final String service;
  final String number;
  final String description;

  const EmergencyNumber({
    required this.country,
    required this.service,
    required this.number,
    required this.description,
  });
}

// Enums
enum EmergencyType {
  medical,
  accident,
  theft,
  assault,
  harassment,
  stranded,
  sos,
  general;

  static EmergencyType fromString(String value) {
    return EmergencyType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => EmergencyType.general,
    );
  }
}

enum EmergencyStatus {
  active,
  resolved,
  cancelled;

  static EmergencyStatus fromString(String value) {
    return EmergencyStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => EmergencyStatus.active,
    );
  }
}

enum EmergencyActionType {
  contactsNotified,
  authoritiesContacted,
  messageSent,
  callMade,
  locationShared;

  static EmergencyActionType fromString(String value) {
    return EmergencyActionType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => EmergencyActionType.contactsNotified,
    );
  }
}

enum EmergencySeverity {
  low,
  medium,
  high,
  critical;

  static EmergencySeverity fromString(String value) {
    return EmergencySeverity.values.firstWhere(
      (severity) => severity.toString().split('.').last == value,
      orElse: () => EmergencySeverity.medium,
    );
  }
}

// Result class
class EmergencyResult {
  final bool isSuccess;
  final String? error;
  final EmergencyIncident? incident;

  const EmergencyResult._({required this.isSuccess, this.error, this.incident});

  factory EmergencyResult.success([EmergencyIncident? incident]) {
    return EmergencyResult._(isSuccess: true, incident: incident);
  }

  factory EmergencyResult.failure(String error) {
    return EmergencyResult._(isSuccess: false, error: error);
  }
}
