import 'package:flutter/material.dart';
import 'package:jobseeker/core/constants.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';

/// First-login profile setup: pick industry + experience level (US03).
/// On save, AuthGate's profile stream flips the user into the dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _userRepo = UserRepository();
  String? _industry;
  String? _level;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_industry == null || _level == null) return;
    setState(() => _isSaving = true);
    try {
      await _userRepo.completeOnboarding(
        industry: _industry!,
        experienceLevel: _level!,
      );
      // AuthGate reacts to the profile update and shows MainScreen (US03.5).
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
    final canSubmit = _industry != null && _level != null && !_isSaving;
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Bantu kami menyesuaikan konten karir untukmu.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          const Text('Industri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _industry,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Pilih industri',
            ),
            items: kIndustries
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: (v) => setState(() => _industry = v),
          ),
          const SizedBox(height: 24),
          const Text('Level Pengalaman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v),
            child: Column(
              children: kExperienceLevels
                  .map(
                    (lvl) => RadioListTile<String>(
                      value: lvl,
                      title: Text(lvl),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSubmit ? _save : null,
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
