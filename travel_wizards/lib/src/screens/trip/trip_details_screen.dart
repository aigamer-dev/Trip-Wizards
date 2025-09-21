import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'widgets/widgets.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    // Body-only screen; title is controlled by NavShell via AppBarTitleController
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripBreadcrumb(tripId: widget.tripId),
                Gaps.h8,
                DefaultTextStyle(
                  style:
                      Theme.of(context).textTheme.headlineSmall ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                  child: TripTitle(tripId: widget.tripId),
                ),
                const SizedBox(height: 12),
                TripStatus(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripMainInfo(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripItineraryCard(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripBookingStatusCard(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripInvoiceCard(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripPackingList(tripId: widget.tripId),
                const SizedBox(height: 16),
                TripInvitesList(tripId: widget.tripId),
                const SizedBox(height: 80), // Extra space for actions bar
              ],
            ),
          ),
        ),
        // Actions bar always visible at bottom
        SafeArea(
          top: false,
          left: false,
          right: false,
          child: TripActionsBar(tripId: widget.tripId),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}