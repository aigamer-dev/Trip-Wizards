import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';
import 'travel_components.dart';

/// Demo page for the Travel Wizards design system components.
///
/// This page showcases all the components in the design system for visual QA.
class ComponentsDemoPage extends StatelessWidget {
  const ComponentsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Design System Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buttons', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                PrimaryButton(
                  onPressed: () {},
                  child: const Text('Primary Button'),
                ),
                const SizedBox(width: DesignTokens.space2),
                SecondaryButton(
                  onPressed: () {},
                  child: const Text('Secondary Button'),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),

            Text('Text Fields', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            TravelTextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            TravelTextField(
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: DesignTokens.space4),

            Text('Cards', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            TravelCard(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Card',
                      style: DesignTokens.textTheme.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'This is a sample card demonstrating the TravelCard component.',
                      style: DesignTokens.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),

            Text('Trip Cards', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            HomeTripCard(
              airlineLogo: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flight, color: colorScheme.primary),
              ),
              airlineName: 'Air India',
              flightNumber: 'AI 301',
              departureTime: '10:30',
              arrivalTime: '14:45',
              duration: '4h 15m',
              stops: 'Non-stop',
              price: 12500,
              currency: '₹',
              departureAirport: 'DEL (Delhi)',
              arrivalAirport: 'BOM (Mumbai)',
              aircraftType: 'Boeing 737',
              baggageInfo: '20kg checked baggage included',
              fareRules:
                  'Changes allowed with fee. Cancellation allowed with fee.',
              onBookNow: () {},
            ),
            const SizedBox(height: DesignTokens.space4),

            Text('Avatars', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                TravelAvatar(child: Text('JD')),
                const SizedBox(width: DesignTokens.space2),
                TravelAvatar(child: Icon(Icons.person)),
                const SizedBox(width: DesignTokens.space2),
                TravelAvatar(radius: 24, child: Text('SM')),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),

            Text('Color Palette', style: DesignTokens.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            Wrap(
              spacing: DesignTokens.space1,
              runSpacing: DesignTokens.space1,
              children: [
                _ColorSwatch('Primary', colorScheme.primary),
                _ColorSwatch('Secondary', colorScheme.secondary),
                _ColorSwatch('Tertiary', colorScheme.tertiary),
                _ColorSwatch('Error', colorScheme.error),
                _ColorSwatch('Surface', colorScheme.surface),
                _ColorSwatch('Background', colorScheme.surface),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.smallRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          name,
          style: DesignTokens.textTheme.labelSmall?.copyWith(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
