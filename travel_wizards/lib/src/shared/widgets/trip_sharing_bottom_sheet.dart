import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/clean_trip_sharing_service.dart'
    as clean_service;

class TripSharingBottomSheet extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  final List<Map<String, dynamic>> destinations;

  const TripSharingBottomSheet({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.destinations,
  });

  @override
  State<TripSharingBottomSheet> createState() => _TripSharingBottomSheetState();
}

class _TripSharingBottomSheetState extends State<TripSharingBottomSheet> {
  final _sharingService = clean_service.TripSharingService.instance;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Gaps.h16,

          // Title
          Text('Share Trip', style: theme.textTheme.headlineSmall),
          Gaps.h8,
          Text(
            widget.tripTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gaps.h24,

          // Sharing options
          if (_isSharing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                _buildSharingOption(
                  icon: Symbols.share_rounded,
                  title: 'Share via Apps',
                  subtitle: 'Share using installed apps',
                  onTap: _shareViaApps,
                  theme: theme,
                ),
                _buildSharingOption(
                  icon: Symbols.link_rounded,
                  title: 'Copy Share Link',
                  subtitle: 'Copy shareable link to clipboard',
                  onTap: _copyShareLink,
                  theme: theme,
                ),
                _buildSharingOption(
                  icon: Symbols.qr_code_rounded,
                  title: 'QR Code',
                  subtitle: 'Generate QR code for sharing',
                  onTap: _generateQRCode,
                  theme: theme,
                ),
                _buildSharingOption(
                  icon: Symbols.picture_as_pdf_rounded,
                  title: 'Export as PDF',
                  subtitle: 'Create and share PDF summary',
                  onTap: _exportAsPDF,
                  theme: theme,
                ),
              ],
            ),

          // Bottom padding for safe area
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSharingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Symbols.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }

  Future<void> _shareViaApps() async {
    await _executeShareAction(() async {
      await _sharingService.shareTrip(
        tripId: widget.tripId,
        tripTitle: widget.tripTitle,
        destinations: widget.destinations
            .map((d) => d['name'] as String? ?? '')
            .toList(),
      );
    });
  }

  Future<void> _copyShareLink() async {
    await _executeShareAction(() async {
      final shareLink = await _sharingService.generateShareableLink(
        widget.tripId,
      );

      await Clipboard.setData(ClipboardData(text: shareLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Share link copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _generateQRCode() async {
    await _executeShareAction(() async {
      final qrData = await _sharingService.generateQrCodeData(widget.tripId);

      if (mounted) {
        // Show QR code in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QR Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    qrData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Scan this QR code to view the trip'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _exportAsPDF() async {
    await _executeShareAction(() async {
      // Create trip data map for PDF export
      final tripData = {
        'id': widget.tripId,
        'title': widget.tripTitle,
        'destinations': widget.destinations,
      };

      await _sharingService.shareTripAsPdf(
        tripId: widget.tripId,
        tripData: tripData,
      );
    });
  }

  Future<void> _executeShareAction(Future<void> Function() action) async {
    try {
      setState(() {
        _isSharing = true;
      });

      await action();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing trip: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
