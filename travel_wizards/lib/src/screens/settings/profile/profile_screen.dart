import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_wizards/src/data/profile_store.dart';
import 'package:travel_wizards/src/data/profile_store_compat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _foodPrefController = TextEditingController();
  final _allergiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    () async {
      await ProfileStore.instance.load();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _nameController.text = ProfileStore.instance.name;
        _emailController.text = ProfileStore.instance.email;
        _dobController.text = prefs.getString('profile_dob') ?? '';
        _stateController.text = prefs.getString('profile_state') ?? '';
        _cityController.text = prefs.getString('profile_city') ?? '';
        _foodPrefController.text = prefs.getString('profile_food_pref') ?? '';
        _allergiesController.text = prefs.getString('profile_allergies') ?? '';
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ProfileStore.instance.updateAll(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  dob: _dobController.text.trim(),
                  state: _stateController.text.trim(),
                  city: _cityController.text.trim(),
                  foodPref: _foodPrefController.text.trim(),
                  allergies: _allergiesController.text.trim(),
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile saved')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dobController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            hintText: 'YYYY-MM-DD',
            suffixIcon: Icon(Icons.calendar_today_rounded),
          ),
          onTap: () async {
            final now = DateTime.now();
            final initialDate = _dobController.text.isNotEmpty
                ? DateTime.tryParse(_dobController.text) ??
                      DateTime(now.year - 20, now.month, now.day)
                : DateTime(now.year - 20, now.month, now.day);
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: now,
              initialDate: initialDate,
            );
            if (picked != null) {
              _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _stateController,
          decoration: const InputDecoration(labelText: 'State'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'City'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _foodPrefController,
          decoration: const InputDecoration(labelText: 'Food preference'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _allergiesController,
          decoration: const InputDecoration(labelText: 'Allergies'),
          maxLines: 2,
        ),
      ],
    );
  }
}
