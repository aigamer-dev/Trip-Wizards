import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Dialog for adding a new itinerary item to a trip
class AddItineraryDialog extends StatefulWidget {
  final String tripId;

  const AddItineraryDialog({super.key, required this.tripId});

  @override
  State<AddItineraryDialog> createState() => _AddItineraryDialogState();
}

class _AddItineraryDialogState extends State<AddItineraryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  String _category = 'Activity';
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Activity',
    'Transportation',
    'Accommodation',
    'Dining',
    'Sightseeing',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitItinerary() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final startDateTime = _combineDateTime(_startDate, _startTime);
      final endDateTime = _combineDateTime(_endDate, _endTime);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(widget.tripId)
          .collection('itinerary')
          .add({
            'title': _titleController.text.trim(),
            'location': _locationController.text.trim(),
            'notes': _notesController.text.trim(),
            'category': _category,
            'start': startDateTime?.toIso8601String(),
            'end': endDateTime?.toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary item added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Symbols.add_circle_outline, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Add Itinerary Item'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Visit Taj Mahal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Symbols.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Symbols.category_rounded),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Agra, India',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Symbols.location_on_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Text('Start Date & Time *', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(
                        Symbols.calendar_today_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _startDate != null
                            ? dateFormat.format(_startDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: const Icon(Symbols.schedule_rounded, size: 18),
                      label: Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Time',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'End Date & Time (Optional)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(
                        Symbols.calendar_today_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _endDate != null
                            ? dateFormat.format(_endDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, false),
                      icon: const Icon(Symbols.schedule_rounded, size: 18),
                      label: Text(
                        _endTime != null ? _endTime!.format(context) : 'Time',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional details...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Symbols.notes_rounded),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submitItinerary,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Symbols.add_rounded),
          label: Text(_isSubmitting ? 'Adding...' : 'Add'),
        ),
      ],
    );
  }
}
