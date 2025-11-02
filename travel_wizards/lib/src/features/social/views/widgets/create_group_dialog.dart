import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/services/social_features_service.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Travel Group'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a group name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Group Description',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a group description' : null,
              ),
              SwitchListTile(
                title: const Text('Private Group'),
                value: _isPrivate,
                onChanged: (value) => setState(() => _isPrivate = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<SocialFeaturesService>().createTravelGroup(
                name: _nameController.text,
                description: _descriptionController.text,
                isPrivate: _isPrivate,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Travel group created!')),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
