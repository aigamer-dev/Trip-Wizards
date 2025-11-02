import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final horizontalPadding = isMobile ? 16.0 : 24.0;

        return ModernPageScaffold(
          pageTitle: 'Trip Details',
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TripBreadcrumb(tripId: widget.tripId),
                      const VGap(Insets.sm),
                      DefaultTextStyle(
                        style:
                            Theme.of(context).textTheme.headlineSmall ??
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                        child: TripTitle(tripId: widget.tripId),
                      ),
                      const VGap(Insets.md),
                      TripStatus(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripMainInfo(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripItineraryCard(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripBookingStatusCard(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripInvoiceCard(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripPackingList(tripId: widget.tripId),
                      const VGap(Insets.lg),
                      TripInvitesList(tripId: widget.tripId),
                      const VGap(Insets.xxl), // Extra space for actions bar
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
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
