import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// Share trip via native share dialog
  Future<void> shareTrip({
    required String tripId,
    required String tripTitle,
    required List<String> destinations,
    String? customMessage,
  }) async {
    try {
      final shareableLink = await generateShareableLink(tripId);

      final message =
          customMessage ??
          'Check out my trip to ${destinations.join(", ")}! 🌍✈️';

      final shareText = '$message\n\n$tripTitle\n$shareableLink';

      await Share.share(shareText, subject: 'Trip: $tripTitle');

      // Track sharing activity
      await _trackSharingActivity(tripId, 'native_share');
    } catch (e) {
      throw Exception('Failed to share trip: $e');
    }
  }

  /// Share trip as PDF export
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
      final shareableLink = await generateShareableLink(tripId);
      await Clipboard.setData(ClipboardData(text: shareableLink));
      await _trackSharingActivity(tripId, 'copy_link');
    } catch (e) {
      throw Exception('Failed to copy shareable link: $e');
    }
  }

  /// Share trip via QR code data
  Future<String> generateQrCodeData(String tripId) async {
    try {
      final shareableLink = await generateShareableLink(tripId);
      await _trackSharingActivity(tripId, 'qr_code');
      return shareableLink;
    } catch (e) {
      throw Exception('Failed to generate QR code data: $e');
    }
  }

  /// Get trip data from shared link
  Future<Map<String, dynamic>?> getTripFromSharedLink(String shareId) async {
    try {
      final shareDoc = await _firestore
          .collection('shared_trips')
          .doc(shareId)
          .get();

      if (!shareDoc.exists) {
        throw Exception('Shared trip not found');
      }

      final shareData = shareDoc.data()!;

      // Check if share is still active and not expired
      if (!shareData['isActive']) {
        throw Exception('This shared link is no longer active');
      }

      final expiresAt = (shareData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('This shared link has expired');
      }

      // Increment view count
      await shareDoc.reference.update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });

      // Get the actual trip data
      final tripId = shareData['tripId'];
      final ownerId = shareData['ownerId'];

      final tripDoc = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('trips')
          .doc(tripId)
          .get();

      if (!tripDoc.exists) {
        throw Exception('Trip data not found');
      }

      final tripData = tripDoc.data()!;

      // Add sharing metadata
      tripData['_shared'] = {
        'shareId': shareId,
        'sharedBy': ownerId,
        'accessLevel': shareData['accessLevel'],
        'sharedAt': shareData['sharedAt'],
      };

      return tripData;
    } catch (e) {
      throw Exception('Failed to access shared trip: $e');
    }
  }

  /// Get sharing analytics for a trip
  Future<Map<String, dynamic>> getSharingAnalytics(String tripId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get all shares for this trip
      final sharesQuery = await _firestore
          .collection('shared_trips')
          .where('tripId', isEqualTo: tripId)
          .where('ownerId', isEqualTo: userId)
          .get();

      int totalShares = sharesQuery.docs.length;
      int totalViews = 0;
      int activeShares = 0;

      for (final doc in sharesQuery.docs) {
        final data = doc.data();
        totalViews += (data['viewCount'] as int? ?? 0);
        if (data['isActive'] == true) {
          final expiresAt = (data['expiresAt'] as Timestamp).toDate();
          if (DateTime.now().isBefore(expiresAt)) {
            activeShares++;
          }
        }
      }

      // Get sharing activity
      final activityQuery = await _firestore
          .collection('sharing_activity')
          .where('tripId', isEqualTo: tripId)
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> activityByType = {};
      for (final doc in activityQuery.docs) {
        final type = doc.data()['type'] as String;
        activityByType[type] = (activityByType[type] ?? 0) + 1;
      }

      return {
        'totalShares': totalShares,
        'totalViews': totalViews,
        'activeShares': activeShares,
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
      });
    } catch (e) {
      throw Exception('Failed to revoke shared link: $e');
    }
  }

  /// Get all active shares for a user's trips
  Future<List<Map<String, dynamic>>> getUserSharedTrips() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final sharesQuery = await _firestore
          .collection('shared_trips')
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('sharedAt', descending: true)
          .get();

      List<Map<String, dynamic>> shares = [];

      for (final doc in sharesQuery.docs) {
        final shareData = doc.data();
        shareData['shareId'] = doc.id;

        // Get trip title for display
        try {
          final tripDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('trips')
              .doc(shareData['tripId'])
              .get();

          if (tripDoc.exists) {
            shareData['tripTitle'] =
                tripDoc.data()?['title'] ?? 'Untitled Trip';
          }
        } catch (e) {
          shareData['tripTitle'] = 'Untitled Trip';
        }

        shares.add(shareData);
      }

      return shares;
    } catch (e) {
      throw Exception('Failed to get user shared trips: $e');
    }
  }

  /// Track sharing activity for analytics
  Future<void> _trackSharingActivity(String tripId, String type) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('sharing_activity').add({
        'tripId': tripId,
        'userId': userId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to track sharing activity: $e');
    }
  }

  /// Generate PDF content (simplified implementation)
  String _generateTripPdfContent(Map<String, dynamic> tripData) {
    final buffer = StringBuffer();

    buffer.writeln('TRAVEL ITINERARY');
    buffer.writeln('================');
    buffer.writeln();
    buffer.writeln('Trip: ${tripData['title'] ?? 'Untitled'}');

    if (tripData['destinations'] != null) {
      buffer.writeln(
        'Destinations: ${(tripData['destinations'] as List).join(', ')}',
      );
    }

    if (tripData['startDate'] != null) {
      buffer.writeln('Start Date: ${tripData['startDate']}');
    }

    if (tripData['endDate'] != null) {
      buffer.writeln('End Date: ${tripData['endDate']}');
    }

    if (tripData['budget'] != null) {
      buffer.writeln('Budget: \$${tripData['budget']}');
    }

    buffer.writeln();
    buffer.writeln('Generated by Travel Wizards');
    buffer.writeln('https://travelwizards.app');

    return buffer.toString();
  }
}

/// Extension to add sharing capabilities to existing trip widgets
mixin TripSharingMixin {
  /// Show sharing options dialog
  Future<void> showSharingOptions({
    required BuildContext context,
    required String tripId,
    required String tripTitle,
    required List<String> destinations,
    Map<String, dynamic>? tripData,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => TripSharingBottomSheet(
        tripId: tripId,
        tripTitle: tripTitle,
        destinations: destinations,
        tripData: tripData,
      ),
    );
  }
}

/// Bottom sheet widget for sharing options
class TripSharingBottomSheet extends StatelessWidget {
  final String tripId;
  final String tripTitle;
  final List<String> destinations;
  final Map<String, dynamic>? tripData;

  const TripSharingBottomSheet({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.destinations,
    this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Share Trip', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          Text(tripTitle, style: theme.textTheme.titleMedium),
          Text(
            destinations.join(', '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildSharingOption(
            context,
            icon: Icons.share,
            title: 'Share Link',
            subtitle: 'Share via messages, email, or social media',
            onTap: () => _shareNative(context),
          ),
          _buildSharingOption(
            context,
            icon: Icons.link,
            title: 'Copy Link',
            subtitle: 'Copy shareable link to clipboard',
            onTap: () => _copyLink(context),
          ),
          _buildSharingOption(
            context,
            icon: Icons.qr_code,
            title: 'QR Code',
            subtitle: 'Generate QR code for easy sharing',
            onTap: () => _showQrCode(context),
          ),
          if (tripData != null)
            _buildSharingOption(
              context,
              icon: Icons.picture_as_pdf,
              title: 'Export PDF',
              subtitle: 'Save or share as PDF document',
              onTap: () => _exportPdf(context),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSharingOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _shareNative(BuildContext context) async {
    try {
      Navigator.of(context).pop();
      await TripSharingService.instance.shareTrip(
        tripId: tripId,
        tripTitle: tripTitle,
        destinations: destinations,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing trip: $e')));
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      Navigator.of(context).pop();
      await TripSharingService.instance.copyShareableLink(tripId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Link copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error copying link: $e')));
      }
    }
  }

  Future<void> _showQrCode(BuildContext context) async {
    try {
      final qrData = await TripSharingService.instance.generateQrCodeData(
        tripId,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        _showQrCodeDialog(context, qrData);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating QR code: $e')));
      }
    }
  }

  void _showQrCodeDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for QR code - in real app would use qr_flutter package
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 64),
                    SizedBox(height: 8),
                    Text('QR Code'),
                    Text('(Scan to view trip)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan this QR code to view the trip',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: qrData));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              }
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      Navigator.of(context).pop();
      await TripSharingService.instance.shareTripAsPdf(
        tripId: tripId,
        tripData: tripData!,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }
}
