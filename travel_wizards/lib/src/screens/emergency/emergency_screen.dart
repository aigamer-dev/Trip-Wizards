import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_wizards/src/services/emergency_service.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

/// Screen for emergency contacts and SOS functionality
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  final EmergencyService _emergencyService = EmergencyService.instance;
  late TabController _tabController;

  bool _isLoading = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeEmergencyService();
    _getCurrentLocation();
  }

  Future<void> _initializeEmergencyService() async {
    if (!_emergencyService.isInitialized) {
      setState(() => _isLoading = true);
      try {
        await _emergencyService.initialize();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initialize emergency service: $e'),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = position);
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade800,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade800,
          tabs: const [
            Tab(text: 'SOS', icon: Icon(Icons.emergency)),
            Tab(text: 'Contacts', icon: Icon(Icons.contacts)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSOSTab(),
                _buildContactsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildSOSTab() {
    return SingleChildScrollView(
      padding: Insets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency SOS Button
          Container(
            width: double.infinity,
            padding: Insets.allLg,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _triggerSOS,
                      borderRadius: BorderRadius.circular(60),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emergency SOS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to send emergency message to all contacts',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Emergency Actions
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildEmergencyTypeCard(
                  'Medical',
                  Icons.medical_services,
                  Colors.red,
                  () => _triggerEmergency(EmergencyType.medical),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmergencyTypeCard(
                  'Accident',
                  Icons.car_crash,
                  Colors.orange,
                  () => _triggerEmergency(EmergencyType.accident),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildEmergencyTypeCard(
                  'Theft',
                  Icons.security,
                  Colors.purple,
                  () => _triggerEmergency(EmergencyType.theft),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmergencyTypeCard(
                  'Stranded',
                  Icons.location_off,
                  Colors.blue,
                  () => _triggerEmergency(EmergencyType.stranded),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Local Emergency Numbers
          _buildLocalEmergencyNumbers(),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: Insets.allMd,
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalEmergencyNumbers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Numbers',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        FutureBuilder<List<EmergencyNumber>>(
          future: _currentLocation != null
              ? _emergencyService.getLocalEmergencyNumbers(_currentLocation!)
              : Future.value([]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final numbers = snapshot.data!;

            return Card(
              child: Column(
                children: numbers
                    .map(
                      (number) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(
                            _getServiceIcon(number.service),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(number.service),
                        subtitle: Text(number.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              number.number,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.phone, color: Colors.red),
                          ],
                        ),
                        onTap: () => _callEmergencyNumber(number.number),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        // Add contact button
        Container(
          width: double.infinity,
          padding: Insets.allMd,
          child: ElevatedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Emergency Contact'),
          ),
        ),

        // Contacts list
        Expanded(
          child: StreamBuilder<List<EmergencyContact>>(
            stream: _emergencyService.contactsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading contacts: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final contacts = snapshot.data ?? [];

              if (contacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No emergency contacts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add trusted contacts for emergencies',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddContactDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: Insets.allMd,
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: contact.isPrimary
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        child: Text(
                          contact.name.isNotEmpty
                              ? contact.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(contact.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.phoneNumber),
                          Text(
                            '${contact.relationship}${contact.isPrimary ? ' • Primary' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) =>
                            _handleContactAction(action, contact),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'call',
                            child: ListTile(
                              leading: Icon(Icons.phone),
                              title: Text('Call'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'message',
                            child: ListTile(
                              leading: Icon(Icons.message),
                              title: Text('Message'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<EmergencyIncident>>(
      stream: _emergencyService.incidentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading history: ${snapshot.error}'),
              ],
            ),
          );
        }

        final incidents = snapshot.data ?? [];

        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No emergency history',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency incidents will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: Insets.allMd,
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getIncidentColor(incident.type),
                  child: Icon(
                    _getIncidentIcon(incident.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(_getIncidentTitle(incident.type)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (incident.description.isNotEmpty)
                      Text(incident.description),
                    Text(
                      _formatDateTime(incident.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(incident.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incident.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _showIncidentDetails(incident),
              ),
            );
          },
        );
      },
    );
  }

  // Action methods
  Future<void> _triggerSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will send an emergency message with your location to all emergency contacts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Send SOS',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _emergencyService.sendSOSMessage(
          location: _currentLocation,
        );

        if (mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS message sent successfully! 🆘'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send SOS: ${result.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending SOS: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _triggerEmergency(EmergencyType type) async {
    final description = await showDialog<String>(
      context: context,
      builder: (context) => _EmergencyDescriptionDialog(type: type),
    );

    if (description != null) {
      try {
        final result = await _emergencyService.triggerEmergency(
          type: type,
          description: description,
          currentLocation: _currentLocation,
          notifyContacts: true,
        );

        if (mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Emergency assistance requested! 🆘'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to request assistance: ${result.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error requesting assistance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _callEmergencyNumber(String number) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Emergency Number'),
        content: Text('Call $number?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _emergencyService.callEmergencyNumber(number);
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to make call')));
      }
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        onContactAdded: (contact) async {
          final result = await _emergencyService.addEmergencyContact(contact);
          if (mounted) {
            if (result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact added successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add contact: ${result.error}'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleContactAction(String action, EmergencyContact contact) {
    switch (action) {
      case 'call':
        _emergencyService.callEmergencyNumber(contact.phoneNumber);
        break;
      case 'message':
        _emergencyService.sendSOSMessage(
          location: _currentLocation,
          specificContacts: [contact.id],
        );
        break;
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'delete':
        _deleteContact(contact);
        break;
    }
  }

  void _showEditContactDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        contact: contact,
        onContactAdded: (updatedContact) async {
          final result = await _emergencyService.updateEmergencyContact(
            updatedContact,
          );
          if (mounted) {
            if (result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact updated successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update contact: ${result.error}'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await _emergencyService.removeEmergencyContact(
                contact.id,
              );
              if (mounted) {
                if (result.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact deleted')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete contact: ${result.error}',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(EmergencyIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getIncidentTitle(incident.type)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (incident.description.isNotEmpty) ...[
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(incident.description),
                const SizedBox(height: 12),
              ],
              Text('Time:', style: Theme.of(context).textTheme.titleSmall),
              Text(_formatDateTime(incident.timestamp)),
              const SizedBox(height: 12),
              Text('Status:', style: Theme.of(context).textTheme.titleSmall),
              Text(incident.status.toString().split('.').last.toUpperCase()),
              if (incident.location != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Location:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${incident.location!.latitude.toStringAsFixed(4)}, ${incident.location!.longitude.toStringAsFixed(4)}',
                ),
              ],
            ],
          ),
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

  // Helper methods
  IconData _getServiceIcon(String service) {
    if (service.toLowerCase().contains('police')) return Icons.local_police;
    if (service.toLowerCase().contains('fire'))
      return Icons.local_fire_department;
    if (service.toLowerCase().contains('ambulance') ||
        service.toLowerCase().contains('medical'))
      return Icons.medical_services;
    return Icons.emergency;
  }

  Color _getIncidentColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return Colors.red;
      case EmergencyType.accident:
        return Colors.orange;
      case EmergencyType.theft:
        return Colors.purple;
      case EmergencyType.assault:
        return Colors.red.shade800;
      case EmergencyType.harassment:
        return Colors.pink;
      case EmergencyType.stranded:
        return Colors.blue;
      case EmergencyType.sos:
        return Colors.red;
      case EmergencyType.general:
        return Colors.grey;
    }
  }

  IconData _getIncidentIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return Icons.medical_services;
      case EmergencyType.accident:
        return Icons.car_crash;
      case EmergencyType.theft:
        return Icons.security;
      case EmergencyType.assault:
        return Icons.warning;
      case EmergencyType.harassment:
        return Icons.report;
      case EmergencyType.stranded:
        return Icons.location_off;
      case EmergencyType.sos:
        return Icons.emergency;
      case EmergencyType.general:
        return Icons.help;
    }
  }

  String _getIncidentTitle(EmergencyType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  Color _getStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.active:
        return Colors.red;
      case EmergencyStatus.resolved:
        return Colors.green;
      case EmergencyStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Dialog widgets
class _EmergencyDescriptionDialog extends StatefulWidget {
  final EmergencyType type;

  const _EmergencyDescriptionDialog({required this.type});

  @override
  State<_EmergencyDescriptionDialog> createState() =>
      _EmergencyDescriptionDialogState();
}

class _EmergencyDescriptionDialogState
    extends State<_EmergencyDescriptionDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${widget.type.toString().split('.').last.toUpperCase()} Emergency',
      ),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Description (optional)',
          hintText: 'Provide details about the emergency...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text(
            'Request Help',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final Function(EmergencyContact) onContactAdded;

  const _AddContactDialog({this.contact, required this.onContactAdded});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;
  bool _isPrimary = false;
  bool _notifyBySMS = true;
  bool _notifyByCall = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.contact?.phoneNumber ?? '',
    );
    _relationshipController = TextEditingController(
      text: widget.contact?.relationship ?? '',
    );
    _isPrimary = widget.contact?.isPrimary ?? false;
    _notifyBySMS = widget.contact?.notifyBySMS ?? true;
    _notifyByCall = widget.contact?.notifyByCall ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.contact != null ? 'Edit Contact' : 'Add Emergency Contact',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Contact name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Spouse, Parent, Friend',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Primary Contact'),
              subtitle: const Text('First contact to notify'),
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Notify by SMS'),
              value: _notifyBySMS,
              onChanged: (value) =>
                  setState(() => _notifyBySMS = value ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Notify by Call'),
              subtitle: const Text('For medical emergencies'),
              value: _notifyByCall,
              onChanged: (value) =>
                  setState(() => _notifyByCall = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          child: Text(widget.contact != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveContact() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }

    final contact = EmergencyContact(
      id:
          widget.contact?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      relationship: _relationshipController.text.isEmpty
          ? 'Contact'
          : _relationshipController.text,
      isPrimary: _isPrimary,
      notifyBySMS: _notifyBySMS,
      notifyByCall: _notifyByCall,
    );

    widget.onContactAdded(contact);
    Navigator.of(context).pop();
  }
}
