import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle trip execution phase including check-ins, real-time updates,
/// and live itinerary management during actual travel
class TripExecutionService {
  static TripExecutionService? _instance;
  static TripExecutionService get instance {
    _instance ??= TripExecutionService._();
    return _instance!;
  }

  TripExecutionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current active trip tracking
  String? _activeTripId;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _periodicUpdateTimer;

  /// Start trip execution tracking
  Future<void> startTripExecution(String tripId) async {
    _activeTripId = tripId;

    try {
      // Update trip status to active
      await _updateTripStatus(tripId, TripExecutionStatus.active);

      // Start location tracking if permission granted
      await _startLocationTracking();

      // Start periodic updates
      _startPeriodicUpdates();

      debugPrint('🚀 Trip execution started for trip: $tripId');
    } catch (e) {
      debugPrint('❌ Failed to start trip execution: $e');
      rethrow;
    }
  }

  /// End trip execution tracking
  Future<void> endTripExecution() async {
    if (_activeTripId == null) return;

    try {
      // Update trip status to completed
      await _updateTripStatus(_activeTripId!, TripExecutionStatus.completed);

      // Stop tracking
      await _stopLocationTracking();
      _stopPeriodicUpdates();

      debugPrint('✅ Trip execution ended for trip: $_activeTripId');
      _activeTripId = null;
    } catch (e) {
      debugPrint('❌ Failed to end trip execution: $e');
    }
  }

  /// Check in to a specific location/activity
  Future<CheckInResult> checkIn({
    required String activityId,
    required String activityName,
    required String location,
    Position? currentPosition,
    String? notes,
    List<String>? photos,
  }) async {
    if (_activeTripId == null) {
      throw Exception('No active trip for check-in');
    }

    try {
      final checkIn = TripCheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: _activeTripId!,
        activityId: activityId,
        activityName: activityName,
        location: location,
        timestamp: DateTime.now(),
        position: currentPosition,
        notes: notes,
        photos: photos ?? [],
        userId: _auth.currentUser?.uid ?? 'unknown',
      );

      // Save check-in to Firestore
      await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .collection('check_ins')
          .doc(checkIn.id)
          .set(checkIn.toMap());

      // Update activity status
      await _updateActivityStatus(activityId, ActivityStatus.completed);

      debugPrint(
        '📍 Check-in completed: ${checkIn.activityName} at ${checkIn.location}',
      );

      return CheckInResult.success(checkIn);
    } catch (e) {
      debugPrint('❌ Check-in failed: $e');
      return CheckInResult.failure(e.toString());
    }
  }

  /// Check out from current location
  Future<CheckOutResult> checkOut({
    required String activityId,
    String? notes,
    int? rating,
  }) async {
    if (_activeTripId == null) {
      throw Exception('No active trip for check-out');
    }

    try {
      final checkOut = TripCheckOut(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: _activeTripId!,
        activityId: activityId,
        timestamp: DateTime.now(),
        notes: notes,
        rating: rating,
        userId: _auth.currentUser?.uid ?? 'unknown',
      );

      // Save check-out to Firestore
      await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .collection('check_outs')
          .doc(checkOut.id)
          .set(checkOut.toMap());

      debugPrint('📤 Check-out completed: Activity $activityId');

      return CheckOutResult.success(checkOut);
    } catch (e) {
      debugPrint('❌ Check-out failed: $e');
      return CheckOutResult.failure(e.toString());
    }
  }

  /// Get current trip status and progress
  Future<TripExecutionStatus?> getCurrentTripStatus() async {
    if (_activeTripId == null) return null;

    try {
      final doc = await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final statusStr = data['executionStatus'] as String?;
        return TripExecutionStatus.values.firstWhere(
          (status) => status.name == statusStr,
          orElse: () => TripExecutionStatus.planned,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to get trip status: $e');
    }

    return null;
  }

  /// Get trip progress (percentage completed)
  Future<double> getTripProgress() async {
    if (_activeTripId == null) return 0.0;

    try {
      // Get total activities
      final activitiesSnapshot = await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .collection('activities')
          .get();

      final totalActivities = activitiesSnapshot.docs.length;
      if (totalActivities == 0) return 0.0;

      // Get completed check-ins
      final checkInsSnapshot = await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .collection('check_ins')
          .get();

      final completedActivities = checkInsSnapshot.docs.length;

      return (completedActivities / totalActivities).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('❌ Failed to calculate trip progress: $e');
      return 0.0;
    }
  }

  /// Get real-time trip updates
  Stream<List<TripUpdate>> getTripUpdatesStream() {
    if (_activeTripId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .doc(_activeTripId!)
        .collection('updates')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TripUpdate.fromMap(doc.data()))
              .toList();
        });
  }

  /// Add real-time trip update
  Future<void> addTripUpdate(TripUpdate update) async {
    if (_activeTripId == null) return;

    try {
      await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .collection('updates')
          .add(update.toMap());

      debugPrint('📱 Trip update added: ${update.message}');
    } catch (e) {
      debugPrint('❌ Failed to add trip update: $e');
    }
  }

  /// Get emergency contacts for current trip
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (_activeTripId == null) return [];

    try {
      final doc = await _firestore
          .collection('trips')
          .doc(_activeTripId!)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final contactsData = data['emergencyContacts'] as List<dynamic>? ?? [];

        return contactsData
            .map(
              (contact) =>
                  EmergencyContact.fromMap(contact as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to get emergency contacts: $e');
    }

    return [];
  }

  /// Trigger emergency assistance
  Future<void> triggerEmergencyAssistance({
    required String type,
    required String message,
    Position? location,
  }) async {
    try {
      final emergency = EmergencyRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: _activeTripId ?? 'no-trip',
        userId: _auth.currentUser?.uid ?? 'unknown',
        type: type,
        message: message,
        location: location,
        timestamp: DateTime.now(),
        status: EmergencyStatus.active,
      );

      // Save emergency request
      await _firestore
          .collection('emergency_requests')
          .doc(emergency.id)
          .set(emergency.toMap());

      // Send notifications (implementation would depend on your notification service)
      debugPrint('🚨 Emergency assistance triggered: $type - $message');
    } catch (e) {
      debugPrint('❌ Failed to trigger emergency assistance: $e');
      rethrow;
    }
  }

  Future<void> _updateTripStatus(
    String tripId,
    TripExecutionStatus status,
  ) async {
    await _firestore.collection('trips').doc(tripId).update({
      'executionStatus': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateActivityStatus(
    String activityId,
    ActivityStatus status,
  ) async {
    if (_activeTripId == null) return;

    await _firestore
        .collection('trips')
        .doc(_activeTripId!)
        .collection('activities')
        .doc(activityId)
        .update({
          'status': status.name,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _startLocationTracking() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        return;
      }

      final settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _locationSubscription =
          Geolocator.getPositionStream(locationSettings: settings).listen((
            position,
          ) {
            _updateCurrentLocation(position);
          });

      debugPrint('📍 Location tracking started');
    } catch (e) {
      debugPrint('❌ Failed to start location tracking: $e');
    }
  }

  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    debugPrint('📍 Location tracking stopped');
  }

  void _startPeriodicUpdates() {
    _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendPeriodicUpdate();
    });
  }

  void _stopPeriodicUpdates() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = null;
  }

  Future<void> _updateCurrentLocation(Position position) async {
    if (_activeTripId == null) return;

    try {
      await _firestore.collection('trips').doc(_activeTripId!).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('❌ Failed to update location: $e');
    }
  }

  Future<void> _sendPeriodicUpdate() async {
    if (_activeTripId == null) return;

    try {
      final progress = await getTripProgress();

      final update = TripUpdate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TripUpdateType.progress,
        message: 'Trip progress: ${(progress * 100).toInt()}% completed',
        timestamp: DateTime.now(),
        metadata: {'progress': progress},
      );

      await addTripUpdate(update);
    } catch (e) {
      debugPrint('❌ Failed to send periodic update: $e');
    }
  }
}

// Data models for trip execution

enum TripExecutionStatus { planned, active, paused, completed, cancelled }

enum ActivityStatus { planned, active, completed, skipped, cancelled }

enum TripUpdateType {
  checkIn,
  checkOut,
  progress,
  location,
  weather,
  delay,
  emergency,
  general,
}

enum EmergencyStatus { active, resolved, escalated }

class TripCheckIn {
  final String id;
  final String tripId;
  final String activityId;
  final String activityName;
  final String location;
  final DateTime timestamp;
  final Position? position;
  final String? notes;
  final List<String> photos;
  final String userId;

  const TripCheckIn({
    required this.id,
    required this.tripId,
    required this.activityId,
    required this.activityName,
    required this.location,
    required this.timestamp,
    this.position,
    this.notes,
    required this.photos,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'activityId': activityId,
      'activityName': activityName,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'position': position != null
          ? {'latitude': position!.latitude, 'longitude': position!.longitude}
          : null,
      'notes': notes,
      'photos': photos,
      'userId': userId,
    };
  }

  factory TripCheckIn.fromMap(Map<String, dynamic> map) {
    return TripCheckIn(
      id: map['id'],
      tripId: map['tripId'],
      activityId: map['activityId'],
      activityName: map['activityName'],
      location: map['location'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      position: map['position'] != null
          ? Position(
              latitude: map['position']['latitude'],
              longitude: map['position']['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            )
          : null,
      notes: map['notes'],
      photos: List<String>.from(map['photos'] ?? []),
      userId: map['userId'],
    );
  }
}

class TripCheckOut {
  final String id;
  final String tripId;
  final String activityId;
  final DateTime timestamp;
  final String? notes;
  final int? rating;
  final String userId;

  const TripCheckOut({
    required this.id,
    required this.tripId,
    required this.activityId,
    required this.timestamp,
    this.notes,
    this.rating,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'activityId': activityId,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'rating': rating,
      'userId': userId,
    };
  }

  factory TripCheckOut.fromMap(Map<String, dynamic> map) {
    return TripCheckOut(
      id: map['id'],
      tripId: map['tripId'],
      activityId: map['activityId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'],
      rating: map['rating'],
      userId: map['userId'],
    );
  }
}

class TripUpdate {
  final String id;
  final TripUpdateType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const TripUpdate({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory TripUpdate.fromMap(Map<String, dynamic> map) {
    return TripUpdate(
      id: map['id'],
      type: TripUpdateType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => TripUpdateType.general,
      ),
      message: map['message'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String email;
  final String relationship;
  final bool isPrimary;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      relationship: map['relationship'],
      isPrimary: map['isPrimary'] ?? false,
    );
  }
}

class EmergencyRequest {
  final String id;
  final String tripId;
  final String userId;
  final String type;
  final String message;
  final Position? location;
  final DateTime timestamp;
  final EmergencyStatus status;

  const EmergencyRequest({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.type,
    required this.message,
    this.location,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'type': type,
      'message': message,
      'location': location != null
          ? {'latitude': location!.latitude, 'longitude': location!.longitude}
          : null,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
    };
  }
}

// Result classes
class CheckInResult {
  final bool isSuccess;
  final TripCheckIn? checkIn;
  final String? error;

  const CheckInResult._(this.isSuccess, this.checkIn, this.error);

  factory CheckInResult.success(TripCheckIn checkIn) =>
      CheckInResult._(true, checkIn, null);

  factory CheckInResult.failure(String error) =>
      CheckInResult._(false, null, error);
}

class CheckOutResult {
  final bool isSuccess;
  final TripCheckOut? checkOut;
  final String? error;

  const CheckOutResult._(this.isSuccess, this.checkOut, this.error);

  factory CheckOutResult.success(TripCheckOut checkOut) =>
      CheckOutResult._(true, checkOut, null);

  factory CheckOutResult.failure(String error) =>
      CheckOutResult._(false, null, error);
}
