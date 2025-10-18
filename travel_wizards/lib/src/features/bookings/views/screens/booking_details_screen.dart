import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/booking_integration_service.dart';
import 'package:travel_wizards/src/shared/services/booking_integration_models.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

/// Enhanced booking details screen with comprehensive booking management
class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  BookingDetails? _bookingDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final details = await context
          .read<BookingIntegrationService>()
          .getBookingDetails(widget.bookingId);

      if (mounted) {
        setState(() {
          _bookingDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading booking: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (_bookingDetails != null) ...[
            IconButton(
              icon: const Icon(Symbols.share_rounded),
              onPressed: _shareBooking,
              tooltip: 'Share booking',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                if (_bookingDetails!.status == BookingStatus.confirmed) ...[
                  const PopupMenuItem(
                    value: 'modify',
                    child: ListTile(
                      leading: Icon(Symbols.edit_rounded),
                      title: Text('Modify Booking'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(Symbols.cancel_rounded),
                      title: Text('Cancel Booking'),
                      dense: true,
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'support',
                  child: ListTile(
                    leading: Icon(Symbols.support_agent_rounded),
                    title: Text('Contact Support'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: _bookingDetails != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Symbols.info_rounded), text: 'Details'),
                  Tab(icon: Icon(Symbols.receipt_rounded), text: 'Receipt'),
                  Tab(icon: Icon(Symbols.timeline_rounded), text: 'Timeline'),
                  Tab(
                    icon: Icon(Symbols.verified_rounded),
                    text: 'Verification',
                  ),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookingDetails == null
          ? _buildErrorState()
          : _buildBookingContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.error_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Booking not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The booking you\'re looking for doesn\'t exist or has been removed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => NavigationService.instance.popOrGoHome(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingContent() {
    return Column(
      children: [
        _buildStatusHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(),
              _buildReceiptTab(),
              _buildTimelineTab(),
              _buildVerificationTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    final booking = _bookingDetails!;
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusColor = theme.colorScheme.primary;
        statusIcon = Symbols.verified_rounded;
        break;
      case BookingStatus.pending:
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Symbols.pending_rounded;
        break;
      case BookingStatus.processing:
        statusColor = theme.colorScheme.secondary;
        statusIcon = Symbols.hourglass_empty_rounded;
        break;
      case BookingStatus.cancelled:
        statusColor = theme.colorScheme.error;
        statusIcon = Symbols.cancel_rounded;
        break;
      case BookingStatus.failed:
        statusColor = theme.colorScheme.error;
        statusIcon = Symbols.error_rounded;
        break;
      case BookingStatus.refunded:
        statusColor = theme.colorScheme.outline;
        statusIcon = Symbols.money_off_rounded;
        break;
    }

    return Container(
      padding: Insets.allMd,
      decoration: BoxDecoration(
        color: statusColor.withAlpha((0.1 * 255).toInt()),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.confirmationCode ?? 'No confirmation code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_getBookingTypeDisplayName(booking.type)} • ${_getStatusDisplayName(booking.status)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                  ),
                ),
                if (booking.totalAmountCents != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(
                      booking.totalAmountCents!,
                      booking.currency ?? 'USD',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final booking = _bookingDetails!;

    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingRequestCard(booking),
          const SizedBox(height: 16),
          if (booking.vendorId != null) _buildVendorCard(booking),
          const SizedBox(height: 16),
          if (booking.confirmation != null) _buildConfirmationCard(booking),
        ],
      ),
    );
  }

  Widget _buildBookingRequestCard(BookingDetails booking) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBookingTypeIcon(booking.type),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getBookingTypeDisplayName(booking.type),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRequestSpecificDetails(booking.request),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSpecificDetails(BookingRequest request) {
    switch (request.type) {
      case BookingType.flight:
        final flight = request as FlightBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Route', '${flight.fromCode} → ${flight.toCode}'),
            _buildDetailRow('Departure', _formatDateTime(flight.departureDate)),
            if (flight.returnDate != null)
              _buildDetailRow('Return', _formatDateTime(flight.returnDate!)),
            _buildDetailRow('Passengers', '${flight.passengers}'),
            _buildDetailRow('Class', flight.classType),
          ],
        );
      case BookingType.hotel:
        final hotel = request as HotelBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Location', hotel.location),
            _buildDetailRow('Check-in', _formatDate(hotel.checkInDate)),
            _buildDetailRow('Check-out', _formatDate(hotel.checkOutDate)),
            _buildDetailRow('Nights', '${hotel.nights}'),
            _buildDetailRow('Rooms', '${hotel.rooms}'),
            _buildDetailRow(
              'Guests',
              '${hotel.adults} adults, ${hotel.children} children',
            ),
            _buildDetailRow('Room Type', hotel.roomType),
          ],
        );
      case BookingType.activity:
        final activity = request as ActivityBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Activity', activity.activityName),
            _buildDetailRow('Location', activity.location),
            _buildDetailRow('Date', _formatDate(activity.activityDate)),
            _buildDetailRow('Time', activity.timeSlot),
            _buildDetailRow('Participants', '${activity.participants}'),
          ],
        );
      case BookingType.transport:
        final transport = request as TransportBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', transport.transportType),
            _buildDetailRow('From', transport.fromLocation),
            _buildDetailRow('To', transport.toLocation),
            _buildDetailRow('Time', _formatDateTime(transport.scheduledTime)),
            _buildDetailRow('Passengers', '${transport.passengers}'),
            _buildDetailRow('Vehicle', transport.vehicleType),
            if (transport.returnTrip)
              _buildDetailRow('Return', _formatDateTime(transport.returnTime!)),
          ],
        );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BookingDetails booking) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.business_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vendor Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Vendor', booking.vendorId!),
            if (booking.vendorBookingId != null)
              _buildDetailRow('Vendor Booking ID', booking.vendorBookingId!),
            if (booking.reservation?.details != null) ...[
              const SizedBox(height: 8),
              ...booking.reservation!.details!.entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value.toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(BookingDetails booking) {
    final confirmation = booking.confirmation!;

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.verified_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirmation Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Confirmation Code', confirmation.confirmationCode),
            _buildDetailRow('Vendor Booking ID', confirmation.vendorBookingId),
            _buildDetailRow(
              'Confirmed At',
              _formatDateTime(confirmation.confirmedAt),
            ),
            _buildDetailRow(
              'Total Amount',
              _formatAmount(
                confirmation.totalAmountCents,
                confirmation.currency,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTab() {
    final booking = _bookingDetails!;

    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReceiptHeader(booking),
          const SizedBox(height: 24),
          _buildPaymentDetails(booking),
          const SizedBox(height: 24),
          _buildReceiptActions(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader(BookingDetails booking) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          children: [
            ProfileAvatar(
              size: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              icon: Symbols.receipt_rounded,
            ),
            Gaps.h16,
            Text(
              'Payment Receipt',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              booking.confirmationCode ?? 'No confirmation code',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BookingDetails booking) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (booking.payment != null) ...[
              _buildDetailRow(
                'Payment ID',
                booking.payment!.paymentId ?? 'N/A',
              ),
              _buildDetailRow(
                'Method',
                booking.payment!.paymentMethod ?? 'N/A',
              ),
              _buildDetailRow(
                'Processed At',
                booking.payment!.processedAt != null
                    ? _formatDateTime(booking.payment!.processedAt!)
                    : 'N/A',
              ),
            ],
            _buildDetailRow(
              'Amount',
              _formatAmount(
                booking.totalAmountCents ?? 0,
                booking.currency ?? 'USD',
              ),
            ),
            _buildDetailRow('Status', _getStatusDisplayName(booking.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Symbols.download_rounded),
            label: const Text('Download'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _emailReceipt,
            icon: const Icon(Symbols.email_rounded),
            label: const Text('Email'),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    final booking = _bookingDetails!;

    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Timeline',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Booking Created',
            _formatDateTime(booking.createdAt),
            Symbols.add_circle_rounded,
            true,
          ),
          if (booking.payment != null)
            _buildTimelineItem(
              'Payment Processed',
              _formatDateTime(booking.payment!.processedAt!),
              Symbols.payment_rounded,
              true,
            ),
          if (booking.confirmation != null)
            _buildTimelineItem(
              'Booking Confirmed',
              _formatDateTime(booking.confirmation!.confirmedAt),
              Symbols.verified_rounded,
              true,
            ),
          if (booking.modifications?.isNotEmpty ?? false) ...[
            for (final mod in booking.modifications!)
              _buildTimelineItem(
                'Booking Modified',
                _formatDateTime(mod.requestedAt),
                Symbols.edit_rounded,
                true,
              ),
          ],
          if (booking.cancellation != null)
            _buildTimelineItem(
              'Booking Cancelled',
              'Cancellation processed',
              Symbols.cancel_rounded,
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    bool completed,
  ) {
    final theme = Theme.of(context);
    final color = completed
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: completed
                  ? color.withAlpha((0.1 * 255).toInt())
                  : Colors.transparent,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: completed ? null : theme.colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTab() {
    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Verification',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildVerificationCard(),
          const SizedBox(height: 16),
          _buildQRCodeCard(),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final booking = _bookingDetails!;

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.security_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verification Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: booking.status == BookingStatus.confirmed
                    ? Theme.of(context).colorScheme.primaryContainer.withAlpha(
                        (0.5 * 255).toInt(),
                      )
                    : Theme.of(context).colorScheme.errorContainer.withAlpha(
                        (0.5 * 255).toInt(),
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    booking.status == BookingStatus.confirmed
                        ? Symbols.verified_rounded
                        : Symbols.warning_rounded,
                    color: booking.status == BookingStatus.confirmed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.status == BookingStatus.confirmed
                          ? 'This booking has been verified and confirmed'
                          : 'This booking requires verification',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          children: [
            Text(
              'Digital Ticket',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Symbols.qr_code_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR code for verification',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'modify':
        _showModifyBookingDialog();
        break;
      case 'cancel':
        _showCancelBookingDialog();
        break;
      case 'support':
        _contactSupport();
        break;
    }
  }

  void _showModifyBookingDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          BookingModificationDialog(booking: _bookingDetails!),
    );
  }

  void _showCancelBookingDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          BookingCancellationDialog(booking: _bookingDetails!),
    );
  }

  void _shareBooking() {
    // Implement booking sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking shared successfully')),
    );
  }

  void _downloadReceipt() {
    // Implement receipt download
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receipt downloaded')));
  }

  void _emailReceipt() {
    // Implement email receipt
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Receipt sent to your email')));
  }

  void _contactSupport() {
    // Implement support contact
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contacting support...')));
  }

  String _getBookingTypeDisplayName(BookingType type) {
    switch (type) {
      case BookingType.flight:
        return 'Flight';
      case BookingType.hotel:
        return 'Hotel';
      case BookingType.activity:
        return 'Activity';
      case BookingType.transport:
        return 'Transport';
    }
  }

  IconData _getBookingTypeIcon(BookingType type) {
    switch (type) {
      case BookingType.flight:
        return Symbols.flight_rounded;
      case BookingType.hotel:
        return Symbols.hotel_rounded;
      case BookingType.activity:
        return Symbols.local_activity_rounded;
      case BookingType.transport:
        return Symbols.directions_car_rounded;
    }
  }

  String _getStatusDisplayName(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.processing:
        return 'Processing';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.failed:
        return 'Failed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.refunded:
        return 'Refunded';
    }
  }

  String _formatAmount(int cents, String currency) {
    final amount = cents / 100.0;
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Dialog for booking modification
class BookingModificationDialog extends StatefulWidget {
  final BookingDetails booking;

  const BookingModificationDialog({super.key, required this.booking});

  @override
  State<BookingModificationDialog> createState() =>
      _BookingModificationDialogState();
}

class _BookingModificationDialogState extends State<BookingModificationDialog> {
  BookingModificationType _selectedType = BookingModificationType.dateChange;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modify Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BookingModificationType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Modification Type',
              border: OutlineInputBorder(),
            ),
            items: BookingModificationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getModificationTypeName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for modification',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitModification,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submitModification() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = BookingModificationRequest(
        type: _selectedType,
        reason: _reasonController.text.trim(),
        changes: {}, // Would contain specific modification details
      );

      final result = await context
          .read<BookingIntegrationService>()
          .modifyBooking(bookingId: widget.booking.id, modification: request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Modification request submitted successfully'
                  : 'Modification failed: ${result.error}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getModificationTypeName(BookingModificationType type) {
    switch (type) {
      case BookingModificationType.dateChange:
        return 'Date Change';
      case BookingModificationType.nameChange:
        return 'Name Change';
      case BookingModificationType.upgrade:
        return 'Upgrade';
      case BookingModificationType.cancellation:
        return 'Cancellation';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

/// Dialog for booking cancellation
class BookingCancellationDialog extends StatefulWidget {
  final BookingDetails booking;

  const BookingCancellationDialog({super.key, required this.booking});

  @override
  State<BookingCancellationDialog> createState() =>
      _BookingCancellationDialogState();
}

class _BookingCancellationDialogState extends State<BookingCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _confirmCancellation = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withAlpha((0.5 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.warning_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cancellation may incur fees and refund processing time.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _confirmCancellation,
            onChanged: (value) {
              setState(() => _confirmCancellation = value ?? false);
            },
            title: const Text('I understand the cancellation policy'),
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || !_confirmCancellation
              ? null
              : _submitCancellation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cancel Booking'),
        ),
      ],
    );
  }

  Future<void> _submitCancellation() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context
          .read<BookingIntegrationService>()
          .cancelBooking(
            bookingId: widget.booking.id,
            reason: _reasonController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Booking cancelled successfully'
                  : 'Cancellation failed: ${result.error}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
