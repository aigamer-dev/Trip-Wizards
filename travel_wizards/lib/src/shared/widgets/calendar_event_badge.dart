import 'package:flutter/material.dart';

/// Badge widget displayed on trip cards imported from device calendar.
/// Shows "Imported from Calendar" label with calendar icon.
class CalendarEventBadge extends StatelessWidget {
  final EdgeInsets padding;
  final double fontSize;

  const CalendarEventBadge({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.blue.shade800 
            : Colors.blue.shade50,
        border: Border.all(
          color: Colors.blue.shade300,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: fontSize + 2,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 4.0),
          Text(
            'Imported from Calendar',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
