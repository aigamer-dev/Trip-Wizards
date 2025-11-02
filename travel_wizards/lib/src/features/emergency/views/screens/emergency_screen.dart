import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/emergency_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

/// Screen for emergency contacts and SOS functionality
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final EmergencyService _emergencyService = EmergencyService.instance;

  bool _isLoading = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentLocation = position);
      }
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernPageScaffold(
      pageTitle: 'Emergency',
      backButtonColor: theme.colorScheme.error,
      sections: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _buildSOSTab(),
          _buildContactsTab(),
          _buildHistoryTab(),
          _buildLocalEmergencyNumbers(),
        ],
      ],
    );
  }

  Widget _buildSOSTab() {
    return ModernSection(
      title: 'Emergency SOS',
      subtitle: 'Tap to send an emergency message to all contacts',
      icon: Symbols.sos,
      highlights: true,
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha((0.3 * 255).toInt()),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _triggerSOS,
              borderRadius: BorderRadius.circular(70),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalEmergencyNumbers() {
    return ModernSection(
      title: 'Local Emergency Numbers',
      icon: Symbols.local_police,
      child: FutureBuilder<List<EmergencyNumber>>(
        future: _currentLocation != null
            ? _emergencyService.getLocalEmergencyNumbers(_currentLocation!)
            : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No local numbers available.');
          }

          final numbers = snapshot.data!;

          return Column(
            children: numbers
                .map(
                  (number) => ListTile(
                    leading: ProfileAvatar(
                      size: 40,
                      backgroundColor: Colors.red,
                      icon: _getServiceIcon(number.service),
                      iconColor: Colors.white,
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
                        const HGap(Insets.sm),
                        const Icon(Symbols.phone, color: Colors.red),
                      ],
                    ),
                    onTap: () => _callEmergencyNumber(number.number),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildContactsTab() {
    return ModernSection(
      title: 'Emergency Contacts',
      icon: Symbols.contacts,
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddContactDialog,
          icon: const Icon(Symbols.add),
          label: const Text('Add'),
        ),
      ],
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
                  const Icon(Symbols.error, size: 64, color: Colors.red),
                  const VGap(Insets.md),
                  Text('Error loading contacts: ${snapshot.error}'),
                ],
              ),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.contacts,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const VGap(Insets.md),
                    Text(
                      'No emergency contacts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const VGap(Insets.sm),
                    Text(
                      'Add trusted contacts for emergencies',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: contacts.map((contact) {
              return ListTile(
                leading: ProfileAvatar(
                  size: 40,
                  backgroundColor: contact.isPrimary
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  initials: contact.name.isNotEmpty
                      ? contact.name[0].toUpperCase()
                      : '?',
                  iconColor: Colors.white,
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
                  onSelected: (action) => _handleContactAction(action, contact),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'call',
                      child: ListTile(
                        leading: Icon(Symbols.phone),
                        title: Text('Call'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'message',
                      child: ListTile(
                        leading: Icon(Symbols.message),
                        title: Text('Message'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Symbols.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Symbols.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ModernSection(
      title: 'Incident History',
      icon: Symbols.history,
      child: StreamBuilder<List<EmergencyIncident>>(
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
                  const Icon(Symbols.error, size: 64, color: Colors.red),
                  const VGap(Insets.md),
                  Text('Error loading history: ${snapshot.error}'),
                ],
              ),
            );
          }

          final incidents = snapshot.data ?? [];

          if (incidents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.history,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const VGap(Insets.md),
                    Text(
                      'No emergency history',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const VGap(Insets.sm),
                    Text(
                      'Emergency incidents will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: incidents.map((incident) {
              return ListTile(
                leading: ProfileAvatar(
                  size: 40,
                  backgroundColor: _getIncidentColor(incident.type),
                  icon: _getIncidentIcon(incident.type),
                  iconColor: Colors.white,
                ),
                title: Text(_getIncidentTitle(incident.type)),
                subtitle: Text(
                  _formatDateTime(incident.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(incident.status),
                    borderRadius: Corners.mdBorder,
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
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Action methods
  Future<void> _triggerSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Symbols.sos, color: Colors.red),
            HGap(Insets.sm),
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
                const VGap(Insets.md),
              ],
              Text('Time:', style: Theme.of(context).textTheme.titleSmall),
              Text(_formatDateTime(incident.timestamp)),
              const VGap(Insets.md),
              Text('Status:', style: Theme.of(context).textTheme.titleSmall),
              Text(incident.status.toString().split('.').last.toUpperCase()),
              if (incident.location != null) ...[
                const VGap(Insets.md),
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
    if (service.toLowerCase().contains('police')) return Symbols.local_police;
    if (service.toLowerCase().contains('fire')) {
      return Symbols.local_fire_department;
    }
    if (service.toLowerCase().contains('ambulance') ||
        service.toLowerCase().contains('medical')) {
      return Symbols.medical_services;
    }
    return Symbols.sos;
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
        return Symbols.medical_services;
      case EmergencyType.accident:
        return Symbols.car_crash;
      case EmergencyType.theft:
        return Symbols.security;
      case EmergencyType.assault:
        return Symbols.warning;
      case EmergencyType.harassment:
        return Symbols.report;
      case EmergencyType.stranded:
        return Symbols.location_off;
      case EmergencyType.sos:
        return Symbols.sos;
      case EmergencyType.general:
        return Symbols.help;
    }
  }

  String _getIncidentTitle(EmergencyType type) {
    // Improved title generation
    final name = type.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
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
  final ValueChanged<EmergencyContact> onContactAdded;

  const _AddContactDialog({this.contact, required this.onContactAdded});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _relationshipController.text = widget.contact!.relationship;
      _isPrimary = widget.contact!.isPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a relationship' : null,
              ),
              SwitchListTile(
                title: const Text('Primary Contact'),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newContact = EmergencyContact(
                id: widget.contact?.id ?? '', // Let service handle ID
                name: _nameController.text,
                phoneNumber: _phoneController.text,
                relationship: _relationshipController.text,
                isPrimary: _isPrimary,
              );
              widget.onContactAdded(newContact);
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.contact == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
