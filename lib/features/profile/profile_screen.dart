import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jobseeker/features/admin/article_seeder.dart';
import 'package:jobseeker/features/admin/manage_articles_screen.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';
import 'package:jobseeker/features/profile/edit_profile_screen.dart';

/// Account info, logout, and (for admins) content-management entry points
/// plus the demo seeder (US07).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepo = UserRepository();
  bool _seeding = false;

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await ArticleSeeder.seed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel contoh ditambahkan.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan artikel contoh.')),
        );
      }
    }
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<AppUser?>(
        stream: _userRepo.watchCurrentProfile(),
        builder: (context, snap) {
          final profile = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile?.fullName?.isNotEmpty == true
                      ? profile!.fullName!
                      : 'No Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Center(
                child: Text(
                  profile?.email ??
                      FirebaseAuth.instance.currentUser?.email ??
                      '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (profile != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(
                        profile.isAdmin
                            ? 'Admin'
                            : profile.isCompany
                            ? 'Company'
                            : 'Job Seeker',
                      ),
                    ),
                  ),
                ),
              if (profile?.isAdmin ?? false)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Chip(label: Text('Admin')),
                  ),
                ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: profile == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        user: profile,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 24),
              _infoTile(
                Icons.phone,
                'Phone Number',
                profile?.phoneNumber ?? '-',
              ),

              _infoTile(
                Icons.description_outlined,
                'Bio',
                profile?.bio ?? '-',
              ),
              _infoTile(Icons.business_center_outlined, 'Industri',
                  profile?.industry ?? '-'),
              _infoTile(Icons.bar_chart, 'Level Pengalaman',
                  profile?.experienceLevel ?? '-'),
              const Divider(height: 32),

              // Admin-only content management (US07.1).
              if (profile?.isAdmin ?? false) ...[
                const Text('Admin',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Kelola Artikel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ManageArticlesScreen()),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _seeding
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Seed Artikel Contoh (dev)'),
                  onTap: _seeding ? null : _seed,
                ),
                const Divider(height: 32),
              ],

              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _userRepo.deleteProfile();

                    if (mounted) {
                      Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}
