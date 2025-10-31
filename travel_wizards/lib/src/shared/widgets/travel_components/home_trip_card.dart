import 'package:flutter/material.dart';
import 'package:travel_wizards/src/ui/design_tokens.dart';

/// HomeTripCard component for displaying flight booking options.
///
/// Shows compact flight details in a single row with airline logo,
/// flight number, duration, stops, price, and "Book Now" button.
/// Includes expandable section for additional details like baggage and fare rules.
class HomeTripCard extends StatefulWidget {
  const HomeTripCard({
    super.key,
    required this.airlineLogo,
    required this.airlineName,
    required this.flightNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.stops,
    required this.price,
    required this.currency,
    this.departureAirport,
    this.arrivalAirport,
    this.aircraftType,
    this.baggageInfo,
    this.fareRules,
    this.onBookNow,
    this.isExpanded = false,
  });

  final Widget airlineLogo;
  final String airlineName;
  final String flightNumber;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String stops;
  final double price;
  final String currency;
  final String? departureAirport;
  final String? arrivalAirport;
  final String? aircraftType;
  final String? baggageInfo;
  final String? fareRules;
  final VoidCallback? onBookNow;
  final bool isExpanded;

  @override
  State<HomeTripCard> createState() => _HomeTripCardState();
}

class _HomeTripCardState extends State<HomeTripCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HomeTripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          // Main flight info row
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Airline logo
                  SizedBox(width: 40, height: 40, child: widget.airlineLogo),
                  const SizedBox(width: 12),

                  // Flight details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Airline name and flight number
                        Row(
                          children: [
                            Text(
                              widget.airlineName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.flightNumber,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Times and duration
                        Row(
                          children: [
                            Text(
                              widget.departureTime,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.arrivalTime,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.duration,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Stops info
                        Text(
                          widget.stops,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.stops.contains('Non-stop')
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price and CTA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.currency}${widget.price.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: widget.onBookNow,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),

                  // Expand/collapse icon
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable details section
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignTokens.cardRadius),
                  bottomRight: Radius.circular(DesignTokens.cardRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Airport details
                  if (widget.departureAirport != null &&
                      widget.arrivalAirport != null)
                    Row(
                      children: [
                        Expanded(
                          child: _buildAirportInfo(
                            'Departure',
                            widget.departureAirport!,
                            theme,
                            scheme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAirportInfo(
                            'Arrival',
                            widget.arrivalAirport!,
                            theme,
                            scheme,
                          ),
                        ),
                      ],
                    ),

                  if (widget.aircraftType != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.airplanemode_active,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aircraft: ${widget.aircraftType}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],

                  // Baggage info
                  if (widget.baggageInfo != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailSection(
                      'Baggage',
                      widget.baggageInfo!,
                      Icons.luggage,
                      theme,
                      scheme,
                    ),
                  ],

                  // Fare rules
                  if (widget.fareRules != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailSection(
                      'Fare Rules',
                      widget.fareRules!,
                      Icons.info_outline,
                      theme,
                      scheme,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirportInfo(
    String label,
    String airport,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          airport,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
