import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/app/travel_icons.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// Weather widget component for displaying destination weather information.
///
/// Shows current weather, temperature, and forecast in a travel-themed design.
class WeatherWidget extends StatelessWidget {
  const WeatherWidget({
    super.key,
    required this.location,
    this.currentCondition,
    this.currentTemp,
    this.tempUnit = '°C',
    this.humidity,
    this.windSpeed,
    this.forecast,
    this.isCompact = false,
  });

  final String location;
  final String? currentCondition;
  final int? currentTemp;
  final String tempUnit;
  final int? humidity;
  final String? windSpeed;
  final List<WeatherForecast>? forecast;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactWeather(context);
    }
    return _buildFullWeather(context);
  }

  Widget _buildCompactWeather(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentCondition != null) ...[
            Icon(
              TravelIcons.getWeatherIcon(currentCondition!),
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
          ],
          if (currentTemp != null) ...[
            Text(
              '$currentTemp$tempUnit',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            TravelIcons.location,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            location,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWeather(BuildContext context) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildCurrentWeather(context),
            if (humidity != null || windSpeed != null) ...[
              const SizedBox(height: 12),
              _buildWeatherDetails(context),
            ],
            if (forecast != null && forecast!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildForecast(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          TravelIcons.location,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          location,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCurrentWeather(BuildContext context) {
    return Row(
      children: [
        if (currentCondition != null) ...[
          Icon(
            TravelIcons.getWeatherIcon(currentCondition!),
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentTemp != null) ...[
                Text(
                  '$currentTemp$tempUnit',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
              if (currentCondition != null) ...[
                const SizedBox(height: 4),
                Text(
                  _capitalizeCondition(currentCondition!),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetails(BuildContext context) {
    return Row(
      children: [
        if (humidity != null) ...[
          Expanded(
            child: _buildDetailItem(
              context,
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: '$humidity%',
            ),
          ),
        ],
        if (windSpeed != null) ...[
          Expanded(
            child: _buildDetailItem(
              context,
              icon: Icons.air,
              label: 'Wind',
              value: windSpeed!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: forecast!.length,
            itemBuilder: (context, index) {
              final day = forecast![index];
              return _buildForecastItem(context, day);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(BuildContext context, WeatherForecast day) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.dayLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            TravelIcons.getWeatherIcon(day.condition),
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            '${day.highTemp}°',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '${day.lowTemp}°',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeCondition(String condition) {
    return condition
        .split(' ')
        .map((word) {
          return word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word;
        })
        .join(' ');
  }
}

/// Weather forecast data model
class WeatherForecast {
  const WeatherForecast({
    required this.dayLabel,
    required this.condition,
    required this.highTemp,
    required this.lowTemp,
  });

  final String dayLabel; // e.g., "Mon", "Tue", "Today"
  final String condition; // e.g., "sunny", "cloudy", "rainy"
  final int highTemp;
  final int lowTemp;
}
