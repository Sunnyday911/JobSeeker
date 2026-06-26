import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';
import 'package:jobseeker/features/widgets/industry_picker.dart';

/// Minimal company onboarding (Change Plan 2.0, Part 1): company name + city +
/// industry. Shown to any `company`-role user that hasn't completed it yet —
/// including existing companies that already finished the seeker onboarding.
/// On save, AuthGate's profile stream flips the company into the dashboard.
class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  State<CompanyOnboardingScreen> createState() =>
      _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  final _userRepo = UserRepository();
  final _nameCtrl = TextEditingController();
  String? _city;
  String? _industry;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _city == null || _industry == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _userRepo.completeCompanyOnboarding(
        companyName: _nameCtrl.text.trim(),
        city: _city!,
        industry: _industry!,
      );
      // AuthGate reacts to the profile update and shows MainScreen.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan. Coba lagi.')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Perusahaan'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Lengkapi data perusahaan untuk mulai memasang lowongan.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          const Text('Nama Perusahaan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Contoh: PT Karya Maju',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          const Text('Kota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _city,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Pilih kota',
            ),
            items: kIndonesianCities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _city = v),
          ),
          const SizedBox(height: 24),
          const Text('Industri/Sektor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          IndustryPicker(
            initial: _industry,
            onChanged: (v) => setState(() => _industry = v),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: (_nameCtrl.text.trim().isNotEmpty &&
                    _city != null &&
                    _industry != null &&
                    !_isSaving)
                ? _save
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
