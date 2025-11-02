import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Service for sharing trips with other users via various methods
class TripSharingService {
  static TripSharingService? _instance;

  static TripSharingService get instance {
    _instance ??= TripSharingService._();
    return _instance!;
  }

  TripSharingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a shareable link for a trip
  Future<String> generateShareableLink(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create a shared trip document
      final shareDoc = await _firestore.collection('shared_trips').add({
        'tripId': tripId,
        'ownerId': userId,
        'sharedAt': FieldValue.serverTimestamp(),
        'accessLevel': 'view', // view, edit, or collaborate
        'expiresAt': DateTime.now().add(
          const Duration(days: 30),
        ), // 30-day expiry
        'isActive': true,
        'viewCount': 0,
      });

      // Generate shareable URL
      final shareId = shareDoc.id;
      final baseUrl = 'https://travelwizards.app'; // Replace with actual domain
      return '$baseUrl/shared/$shareId';
    } catch (e) {
      throw Exception('Failed to generate shareable link: $e');
    }
  }

  /// Share trip using native platform sharing
  Future<void> shareTrip({
    required String tripId,
    required String tripTitle,
    required List<String> destinations,
  }) async {
    try {
      final shareLink = await generateShareableLink(tripId);

      final shareText =
          '''
Check out this amazing trip: $tripTitle

Destinations: ${destinations.join(', ')}

View the full itinerary: $shareLink

Shared via Travel Wizards 🧳✈️
''';

      await Share.share(shareText, subject: 'Trip: $tripTitle');

      await _trackSharingActivity(tripId, 'native_share');
    } catch (e) {
      throw Exception('Failed to share trip: $e');
    }
  }

  /// Share trip as PDF
  Future<void> shareTripAsPdf({
    required String tripId,
    required Map<String, dynamic> tripData,
  }) async {
    try {
      if (kIsWeb) {
        throw Exception('PDF export not supported on web');
      }

      // Generate PDF content (simplified - in real app would use pdf package)
      final pdfContent = _generateTripPdfContent(tripData);

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/trip_${tripId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      // Write PDF content (this would be actual PDF bytes in real implementation)
      await file.writeAsString(pdfContent);

      // Share the file
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Trip itinerary: ${tripData['title']}');

      await _trackSharingActivity(tripId, 'pdf_export');
    } catch (e) {
      throw Exception('Failed to export trip as PDF: $e');
    }
  }

  /// Copy shareable link to clipboard
  Future<void> copyShareableLink(String tripId) async {
    try {
      final shareLink = await generateShareableLink(tripId);
      await Clipboard.setData(ClipboardData(text: shareLink));
      await _trackSharingActivity(tripId, 'copy_link');
    } catch (e) {
      throw Exception('Failed to copy shareable link: $e');
    }
  }

  /// Generate QR code data for trip sharing
  Future<String> generateQrCodeData(String tripId) async {
    try {
      final shareLink = await generateShareableLink(tripId);
      await _trackSharingActivity(tripId, 'qr_code');
      return shareLink;
    } catch (e) {
      throw Exception('Failed to generate QR code data: $e');
    }
  }

  /// Get trip data from shared link
  Future<Map<String, dynamic>?> getTripFromSharedLink(String shareId) async {
    try {
      // Get the shared trip document
      final shareDoc = await _firestore
          .collection('shared_trips')
          .doc(shareId)
          .get();

      if (!shareDoc.exists) {
        return null;
      }

      final shareData = shareDoc.data()!;

      // Check if the link is still active and not expired
      if (!shareData['isActive']) {
        return null;
      }

      final expiresAt = shareData['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return null;
      }

      // Increment view count
      await shareDoc.reference.update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });

      // Get the actual trip data
      final tripId = shareData['tripId'] as String;
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();

      if (!tripDoc.exists) {
        return null;
      }

      final tripData = tripDoc.data()!;
      tripData['id'] = tripDoc.id;

      // Add sharing metadata
      tripData['sharedLink'] = {
        'shareId': shareId,
        'accessLevel': shareData['accessLevel'],
        'sharedBy': shareData['ownerId'],
        'sharedAt': shareData['sharedAt'],
      };

      // Track view analytics
      await _trackViewActivity(shareId, tripId);

      return tripData;
    } catch (e) {
      throw Exception('Failed to get trip from shared link: $e');
    }
  }

  /// Track view activity for analytics
  Future<void> _trackViewActivity(String shareId, String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;

      await _firestore.collection('sharing_analytics').add({
        'shareId': shareId,
        'tripId': tripId,
        'viewerId': userId,
        'viewedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      });
    } catch (e) {
      // Don't throw error for analytics tracking
      debugPrint('Failed to track view activity: $e');
    }
  }

  /// Get sharing analytics for a trip
  Future<Map<String, dynamic>> getSharingAnalytics(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get all shared links for this trip
      final shareQuery = await _firestore
          .collection('shared_trips')
          .where('tripId', isEqualTo: tripId)
          .where('ownerId', isEqualTo: userId)
          .get();

      int totalShares = shareQuery.docs.length;
      int activeShares = 0;
      int totalViews = 0;

      for (final doc in shareQuery.docs) {
        final data = doc.data();
        if (data['isActive'] == true) {
          activeShares++;
        }
        totalViews += (data['viewCount'] as int? ?? 0);
      }

      // Get sharing activity breakdown
      final activityQuery = await _firestore
          .collection('sharing_analytics')
          .where('tripId', isEqualTo: tripId)
          .get();

      Map<String, int> activityByType = {};
      for (final doc in activityQuery.docs) {
        final type = doc.data()['type'] as String? ?? 'unknown';
        activityByType[type] = (activityByType[type] ?? 0) + 1;
      }

      return {
        'totalShares': totalShares,
        'activeShares': activeShares,
        'totalViews': totalViews,
        'activityByType': activityByType,
      };
    } catch (e) {
      throw Exception('Failed to get sharing analytics: $e');
    }
  }

  /// Revoke a shared link
  Future<void> revokeSharedLink(String shareId) async {
    try {
      await _firestore.collection('shared_trips').doc(shareId).update({
        'isActive': false,
        'revokedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to revoke shared link: $e');
    }
  }

  /// Get all shared trips for the current user
  Future<List<Map<String, dynamic>>> getUserSharedTrips() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection('shared_trips')
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('sharedAt', descending: true)
          .get();

      List<Map<String, dynamic>> sharedTrips = [];

      for (final doc in query.docs) {
        final shareData = doc.data();
        final tripId = shareData['tripId'] as String;

        // Get trip title
        try {
          final tripDoc = await _firestore
              .collection('trips')
              .doc(tripId)
              .get();
          if (tripDoc.exists) {
            final tripData = tripDoc.data()!;
            sharedTrips.add({
              'shareId': doc.id,
              'tripId': tripId,
              'tripTitle': tripData['title'] ?? 'Untitled Trip',
              'destinations': tripData['destinations'] ?? [],
              'sharedAt': shareData['sharedAt'],
              'expiresAt': shareData['expiresAt'],
              'viewCount': shareData['viewCount'] ?? 0,
              'accessLevel': shareData['accessLevel'] ?? 'view',
            });
          }
        } catch (e) {
          // Skip trips that can't be loaded
          debugPrint('Failed to load trip $tripId: $e');
        }
      }

      return sharedTrips;
    } catch (e) {
      throw Exception('Failed to get user shared trips: $e');
    }
  }

  /// Track sharing activity for analytics
  Future<void> _trackSharingActivity(String tripId, String type) async {
    try {
      final userId = _auth.currentUser?.uid;

      await _firestore.collection('sharing_analytics').add({
        'tripId': tripId,
        'userId': userId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      });
    } catch (e) {
      // Don't throw error for analytics tracking
      debugPrint('Failed to track sharing activity: $e');
    }
  }

  /// Generate PDF content for a trip (simplified implementation)
  String _generateTripPdfContent(Map<String, dynamic> tripData) {
    final buffer = StringBuffer();

    buffer.writeln('TRAVEL ITINERARY');
    buffer.writeln('================');
    buffer.writeln();
    buffer.writeln('Trip: ${tripData['title'] ?? 'Untitled Trip'}');
    buffer.writeln();

    final destinations = tripData['destinations'] as List<dynamic>? ?? [];
    if (destinations.isNotEmpty) {
      buffer.writeln('DESTINATIONS:');
      for (int i = 0; i < destinations.length; i++) {
        final dest = destinations[i];
        if (dest is Map) {
          buffer.writeln('${i + 1}. ${dest['name'] ?? 'Unknown'}');
          if (dest['description'] != null) {
            buffer.writeln('   ${dest['description']}');
          }
        } else {
          buffer.writeln('${i + 1}. $dest');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('Generated by Travel Wizards');
    buffer.writeln(DateTime.now().toString());

    return buffer.toString();
  }
}
