import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _repo = UserRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
    text: widget.user.fullName ?? '',
    );

    _phoneController = TextEditingController(
    text: widget.user.phoneNumber ?? '',
    );

    _bioController = TextEditingController(
    text: widget.user.bio ?? '',
    );

  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
    await _repo.updateProfile(
    fullName: _nameController.text.trim(),
    phoneNumber: _phoneController.text.trim(),
    bio: _bioController.text.trim(),
    );

    if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration:
                const InputDecoration(labelText: 'Full Name'),
                ),
              const SizedBox(height: 12),

          TextField(
            controller: _phoneController,
            decoration:
            const InputDecoration(labelText: 'Phone'),
          ),
              const SizedBox(height: 12),

          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration:
            const InputDecoration(labelText: 'Bio'),
          ),
              const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
            ? const CircularProgressIndicator()
                : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
