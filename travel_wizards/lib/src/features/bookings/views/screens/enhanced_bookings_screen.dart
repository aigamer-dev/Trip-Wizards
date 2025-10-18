import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/booking_integration_service.dart';
import 'package:travel_wizards/src/shared/services/booking_integration_models.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// Enhanced bookings screen with comprehensive booking management
class EnhancedBookingsScreen extends StatefulWidget {
  const EnhancedBookingsScreen({super.key});

  @override
  State<EnhancedBookingsScreen> createState() => _EnhancedBookingsScreenState();
}

class _EnhancedBookingsScreenState extends State<EnhancedBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  BookingStatus? _filterStatus;
  BookingType? _filterType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final BookingIntegrationService _bookingService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingService = BookingIntegrationService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Bookings'),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: context.canPop()
                ? IconButton(
                    icon: const Icon(Symbols.arrow_back_rounded),
                    tooltip: 'Back',
                    onPressed: () =>
                        NavigationService.instance.popOrGoHome(context),
                  )
                : null,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Symbols.schedule_rounded), text: 'Active'),
                Tab(icon: Icon(Symbols.history_rounded), text: 'History'),
                Tab(icon: Icon(Symbols.analytics_rounded), text: 'Summary'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Symbols.filter_list_rounded),
                onPressed: _showFilterDialog,
                tooltip: 'Filter bookings',
              ),
              IconButton(
                icon: const Icon(Symbols.search_rounded),
                onPressed: _showSearchDialog,
                tooltip: 'Search bookings',
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveBookingsTab(),
              _buildHistoryTab(),
              _buildSummaryTab(),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: FloatingActionButton.extended(
              onPressed: _createNewBooking,
              icon: const Icon(Symbols.add_rounded),
              label: const Text('New Booking'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBookingsTab() {
    return StreamBuilder<List<BookingDetails>>(
      stream: _bookingService.streamUserBookings(
        status: BookingStatus.confirmed,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = _filterBookings(snapshot.data ?? []);

        if (bookings.isEmpty) {
          return _buildEmptyState(
            icon: Symbols.event_busy_rounded,
            title: 'No Active Bookings',
            subtitle: 'Your confirmed bookings will appear here',
            actionLabel: 'Create Booking',
            onAction: _createNewBooking,
          );
        }

        return _buildBookingsList(bookings, showUpcoming: true);
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<BookingDetails>>(
      stream: _bookingService.streamUserBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allBookings = _filterBookings(snapshot.data ?? []);
        final historyBookings = allBookings
            .where(
              (b) => [
                BookingStatus.cancelled,
                BookingStatus.refunded,
                BookingStatus.failed,
              ].contains(b.status),
            )
            .toList();

        if (historyBookings.isEmpty) {
          return _buildEmptyState(
            icon: Symbols.history_rounded,
            title: 'No Booking History',
            subtitle: 'Your past bookings will appear here',
          );
        }

        return _buildBookingsList(historyBookings, showUpcoming: false);
      },
    );
  }

  Widget _buildSummaryTab() {
    return StreamBuilder<List<BookingDetails>>(
      stream: _bookingService.streamUserBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        return _buildBookingSummary(bookings);
      },
    );
  }

  Widget _buildBookingsList(
    List<BookingDetails> bookings, {
    required bool showUpcoming,
  }) {
    // Sort bookings by relevance
    bookings.sort((a, b) {
      if (showUpcoming) {
        // For active bookings, show most recent first
        return b.createdAt.compareTo(a.createdAt);
      } else {
        // For history, show newest first
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh bookings
        setState(() {});
      },
      child: ListView.builder(
        padding: Insets.allMd,
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, showUpcoming: showUpcoming);
        },
      ),
    );
  }

  Widget _buildBookingCard(
    BookingDetails booking, {
    required bool showUpcoming,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBookingTypeIcon(booking.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBookingTitle(booking),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getBookingSubtitle(booking),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const Divider(height: 24),
              _buildBookingDetails(booking),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (booking.totalAmountCents != null)
                    Text(
                      _formatAmount(
                        booking.totalAmountCents!,
                        booking.currency ?? 'USD',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Row(
                    children: [
                      if (showUpcoming &&
                          booking.status == BookingStatus.confirmed)
                        TextButton(
                          onPressed: () => _quickAction(booking),
                          child: const Text('Modify'),
                        ),
                      IconButton(
                        onPressed: () => _showBookingActions(booking),
                        icon: const Icon(Symbols.more_vert_rounded),
                        tooltip: 'More actions',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTypeIcon(BookingType type) {
    IconData icon;
    Color color;

    switch (type) {
      case BookingType.flight:
        icon = Symbols.flight_rounded;
        color = Colors.blue;
        break;
      case BookingType.hotel:
        icon = Symbols.hotel_rounded;
        color = Colors.purple;
        break;
      case BookingType.activity:
        icon = Symbols.local_activity_rounded;
        color = Colors.orange;
        break;
      case BookingType.transport:
        icon = Symbols.directions_car_rounded;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case BookingStatus.processing:
        color = Colors.blue;
        label = 'Processing';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      case BookingStatus.failed:
        color = Colors.red;
        label = 'Failed';
        break;
      case BookingStatus.refunded:
        color = Colors.grey;
        label = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBookingDetails(BookingDetails booking) {
    final theme = Theme.of(context);

    switch (booking.type) {
      case BookingType.flight:
        final flight = booking.request as FlightBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  flight.fromCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Symbols.arrow_forward_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  flight.toCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(flight.departureDate),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${flight.passengers} passenger${flight.passengers > 1 ? 's' : ''} • ${flight.classType}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case BookingType.hotel:
        final hotel = booking.request as HotelBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hotel.location,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${hotel.nights} night${hotel.nights > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(hotel.checkInDate)} - ${_formatDate(hotel.checkOutDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case BookingType.activity:
        final activity = booking.request as ActivityBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.activityName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activity.location} • ${_formatDate(activity.activityDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case BookingType.transport:
        final transport = booking.request as TransportBookingRequest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${transport.fromLocation} → ${transport.toLocation}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDateTime(transport.scheduledTime),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${transport.transportType} • ${transport.passengers} passenger${transport.passengers > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBookingSummary(List<BookingDetails> bookings) {
    final confirmed = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final pending = bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final cancelled = bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;

    final totalSpent = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .fold<int>(0, (sum, b) => sum + (b.totalAmountCents ?? 0));

    final byType = <BookingType, int>{};
    for (final booking in bookings) {
      byType[booking.type] = (byType[booking.type] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Status summary
          Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Confirmed',
                          confirmed,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Pending',
                          pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Cancelled',
                          cancelled,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Spending summary
          Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(totalSpent, 'USD'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Type breakdown
          Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bookings by Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...byType.entries.map((entry) {
                    final percentage = bookings.isNotEmpty
                        ? (entry.value / bookings.length * 100).round()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(_getBookingTypeIcon(entry.key)),
                          const SizedBox(width: 8),
                          Text(_getBookingTypeName(entry.key)),
                          const Spacer(),
                          Text('${entry.value} ($percentage%)'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: Insets.allLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  List<BookingDetails> _filterBookings(List<BookingDetails> bookings) {
    var filtered = bookings;

    if (_filterStatus != null) {
      filtered = filtered.where((b) => b.status == _filterStatus).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((b) => b.type == _filterType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final query = _searchQuery.toLowerCase();
        return b.confirmationCode?.toLowerCase().contains(query) == true ||
            _getBookingTitle(b).toLowerCase().contains(query) ||
            b.vendorId?.toLowerCase().contains(query) == true;
      }).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<BookingStatus?>(
              initialValue: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...BookingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _filterStatus = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BookingType?>(
              initialValue: _filterType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...BookingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBookingTypeName(type)),
                  );
                }),
              ],
              onChanged: (value) => setState(() => _filterType = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterType = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Bookings'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search by confirmation code, type, or vendor',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = _searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _openBookingDetails(BookingDetails booking) {
    context.pushNamed('booking_details', pathParameters: {'id': booking.id});
  }

  void _quickAction(BookingDetails booking) {
    // Show quick modification options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Insets.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.edit_calendar_rounded),
              title: const Text('Change Date'),
              onTap: () {
                Navigator.pop(context);
                // Handle date change
              },
            ),
            ListTile(
              leading: const Icon(Symbols.person_edit_rounded),
              title: const Text('Update Details'),
              onTap: () {
                Navigator.pop(context);
                // Handle detail update
              },
            ),
            ListTile(
              leading: const Icon(Symbols.cancel_rounded),
              title: const Text('Cancel Booking'),
              onTap: () {
                Navigator.pop(context);
                // Handle cancellation
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingActions(BookingDetails booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Insets.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.visibility_rounded),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _openBookingDetails(booking);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.share_rounded),
              title: const Text('Share Booking'),
              onTap: () {
                Navigator.pop(context);
                // Handle sharing
              },
            ),
            ListTile(
              leading: const Icon(Symbols.download_rounded),
              title: const Text('Download Receipt'),
              onTap: () {
                Navigator.pop(context);
                // Handle download
              },
            ),
            if (booking.status == BookingStatus.confirmed) ...[
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Modify Booking'),
                onTap: () {
                  Navigator.pop(context);
                  _quickAction(booking);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _createNewBooking() {
    // Navigate to booking creation flow
    context.pushNamed('plan');
  }

  String _getBookingTitle(BookingDetails booking) {
    switch (booking.type) {
      case BookingType.flight:
        final flight = booking.request as FlightBookingRequest;
        return '${flight.fromCode} to ${flight.toCode}';
      case BookingType.hotel:
        final hotel = booking.request as HotelBookingRequest;
        return hotel.location;
      case BookingType.activity:
        final activity = booking.request as ActivityBookingRequest;
        return activity.activityName;
      case BookingType.transport:
        final transport = booking.request as TransportBookingRequest;
        return '${transport.fromLocation} to ${transport.toLocation}';
    }
  }

  String _getBookingSubtitle(BookingDetails booking) {
    return booking.vendorId ?? 'Unknown vendor';
  }

  String _getBookingTypeName(BookingType type) {
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
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
