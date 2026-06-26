import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';
import 'package:jobseeker/features/widgets/industry_picker.dart';

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

  String? _city;
  String? _industry;

  bool _saving = false;

  bool get _isCompany => widget.user.isCompany;

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

    _city = kIndonesianCities.contains(widget.user.city) ? widget.user.city : null;
    // Raw value so a previously-typed custom industry round-trips in the picker.
    _industry = widget.user.industry;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
    await _repo.updateProfile(
    fullName: _nameController.text.trim(),
    phoneNumber: _phoneController.text.trim(),
    bio: _bioController.text.trim(),
    // Company-only fields — passed only for companies, so the seeker call
    // path is unchanged (Change Plan 2.0, Part 7.3).
    city: _isCompany ? _city : null,
    industry: _isCompany ? _industry : null,
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
                decoration: InputDecoration(
                    labelText: _isCompany ? 'Company Name' : 'Full Name'),
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
              if (_isCompany) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kota'),
                  items: kIndonesianCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _city = v),
                ),
                const SizedBox(height: 12),
                IndustryPicker(
                  label: 'Industri/Sektor',
                  initial: _industry,
                  onChanged: (v) => setState(() => _industry = v),
                ),
              ],
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
