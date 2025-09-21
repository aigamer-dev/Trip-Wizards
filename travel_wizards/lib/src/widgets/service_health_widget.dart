import 'package:flutter/material.dart';
import '../services/service_health_monitor.dart';
import '../services/api_client_models.dart';

/// Widget to display service health status in the app
class ServiceHealthWidget extends StatefulWidget {
  const ServiceHealthWidget({super.key});

  @override
  State<ServiceHealthWidget> createState() => _ServiceHealthWidgetState();
}

class _ServiceHealthWidgetState extends State<ServiceHealthWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceHealthEvent>(
      stream: ServiceHealthMonitor.instance.healthEvents,
      builder: (context, snapshot) {
        final healthSummary = ServiceHealthMonitor.instance.getHealthSummary();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(healthSummary.overallStatus),
                      color: _getStatusColor(healthSummary.overallStatus),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Service Health',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (healthSummary.isMonitoring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Monitoring',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  healthSummary.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getStatusColor(healthSummary.overallStatus),
                  ),
                ),
                if (healthSummary.services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Services:'),
                  const SizedBox(height: 8),
                  ...healthSummary.services.entries.map(
                    (entry) => _buildServiceItem(entry.key, entry.value),
                  ),
                ],
                if (healthSummary.totalServices > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusBadge(
                        'Healthy',
                        healthSummary.healthyCount,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        'Degraded',
                        healthSummary.degradedCount,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        'Unhealthy',
                        healthSummary.unhealthyCount,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceItem(String serviceName, ServiceHealth health) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(health.status),
            size: 16,
            color: _getStatusColor(health.status),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(serviceName, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            '${health.responseTime.inMilliseconds}ms',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getStatusIcon(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.healthy:
        return Icons.check_circle;
      case ServiceHealthStatus.degraded:
        return Icons.warning;
      case ServiceHealthStatus.unhealthy:
        return Icons.error;
      case ServiceHealthStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.healthy:
        return Colors.green;
      case ServiceHealthStatus.degraded:
        return Colors.orange;
      case ServiceHealthStatus.unhealthy:
        return Colors.red;
      case ServiceHealthStatus.unknown:
        return Colors.grey;
    }
  }
}

/// Compact service health indicator for app bars
class ServiceHealthIndicator extends StatelessWidget {
  const ServiceHealthIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceHealthEvent>(
      stream: ServiceHealthMonitor.instance.healthEvents,
      builder: (context, snapshot) {
        final healthSummary = ServiceHealthMonitor.instance.getHealthSummary();

        return IconButton(
          icon: Icon(
            _getStatusIcon(healthSummary.overallStatus),
            color: _getStatusColor(healthSummary.overallStatus),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Service Health'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ServiceHealthWidget(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ServiceHealthMonitor.instance.forceHealthCheckAll();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.healthy:
        return Icons.cloud_done;
      case ServiceHealthStatus.degraded:
        return Icons.cloud_queue;
      case ServiceHealthStatus.unhealthy:
        return Icons.cloud_off;
      case ServiceHealthStatus.unknown:
        return Icons.cloud_outlined;
    }
  }

  Color _getStatusColor(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.healthy:
        return Colors.green;
      case ServiceHealthStatus.degraded:
        return Colors.orange;
      case ServiceHealthStatus.unhealthy:
        return Colors.red;
      case ServiceHealthStatus.unknown:
        return Colors.grey;
    }
  }
}
