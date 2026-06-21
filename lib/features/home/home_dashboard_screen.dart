import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/models/article.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';
import 'package:jobseeker/features/repositories/cv_repository.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';
import 'package:jobseeker/features/services/adzuna_service.dart';
import 'package:jobseeker/features/articles/article_detail_screen.dart';
import 'package:jobseeker/features/articles/articles_feed_screen.dart';
import 'package:jobseeker/features/applications/my_applications_screen.dart';
import 'package:jobseeker/features/cv/cv_analysis_screen.dart';
import 'package:jobseeker/features/cv/recommendations_screen.dart';
import 'package:jobseeker/features/jobs_feed/job_detail_screen.dart';

/// Home dashboard (US15) — aggregates greeting, application stats, AI
/// recommendation CTA, latest jobs, and featured articles into one hub.
/// Body-only (uses MainScreen's AppBar). [onOpenJobsTab] switches the bottom
/// nav to the Lowongan tab.
class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback onOpenJobsTab;
  const HomeDashboardScreen({super.key, required this.onOpenJobsTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _userRepo = UserRepository();
  final _appRepo = ApplicationRepository();
  final _cvRepo = CvRepository();
  final _articleRepo = ArticleRepository();

  AppUser? _profile;
  Future<List<Job>>? _jobsFuture;
  Future<CvProfile?>? _cvFuture;

  @override
  void initState() {
    super.initState();
    _cvFuture = _cvRepo.getProfile();
    _userRepo.getCurrentProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _profile = p;
        _jobsFuture = AdzunaService.instance
            .searchJobs(what: p?.industry ?? '', resultsPerPage: 5);
      });
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _cvFuture = _cvRepo.getProfile();
      _jobsFuture = AdzunaService.instance
          .searchJobs(what: _profile?.industry ?? '', resultsPerPage: 5);
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$_greeting,',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            _profile?.fullName?.isNotEmpty == true
                ? _profile!.fullName!
                : 'User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _statsSection(),
          const SizedBox(height: 24),
          _recommendationCta(),
          const SizedBox(height: 24),
          _latestJobsSection(),
          const SizedBox(height: 24),
          _featuredArticlesSection(),
        ],
      ),
    );
  }

  // ---- Application stats (US15.2) ----
  Widget _statsSection() {
    return StreamBuilder<List<Application>>(
      stream: _appRepo.watchMyApplications(),
      builder: (context, snap) {
        final apps = snap.data ?? [];
        final total = apps.length;
        final interview = apps.where((a) => a.status == 'Interview').length;
        final aktif = apps
            .where((a) =>
                a.status != 'Ditolak' && a.status != 'Tawaran Diterima')
            .length;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              _statCard('Total', total),
              const SizedBox(width: 8),
              _statCard('Aktif', aktif),
              const SizedBox(width: 8),
              _statCard('Interview', interview),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );

  // ---- Recommendation CTA (US15.3) ----
  Widget _recommendationCta() {
    return FutureBuilder<CvProfile?>(
      future: _cvFuture,
      builder: (context, snap) {
        final hasProfile = snap.data != null;
        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(hasProfile
                ? 'Rekomendasi lowongan untukmu'
                : 'Analisis CV dengan AI'),
            subtitle: Text(hasProfile
                ? 'Lihat lowongan yang cocok dengan profil CV-mu'
                : 'Dapatkan rekomendasi lowongan dari CV-mu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => hasProfile
                    ? const RecommendationsScreen()
                    : const CvAnalysisScreen(),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Latest jobs (US15.4) ----
  Widget _latestJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Lowongan Terbaru', widget.onOpenJobsTab),
        const SizedBox(height: 8),
        if (_jobsFuture == null)
          const Center(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator()),
          )
        else
          FutureBuilder<List<Job>>(
            future: _jobsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator()),
                );
              }
              final jobs = (snap.data ?? []).take(3).toList();
              if (jobs.isEmpty) return const Text('Belum ada lowongan.');
              return Column(
                children: jobs
                    .map((job) => Card(
                          child: ListTile(
                            title: Text(job.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text('${job.company} • ${job.location}',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => JobDetailScreen(job: job)),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  // ---- Featured articles (US15.5) ----
  Widget _featuredArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Artikel Panduan Karir',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArticlesFeedScreen()),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: StreamBuilder<List<Article>>(
            stream: _articleRepo.watchPublished(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final articles = (snap.data ?? []).take(6).toList();
              if (articles.isEmpty) {
                return const Center(child: Text('Belum ada artikel.'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final a = articles[i];
                  return SizedBox(
                    width: 200,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ArticleDetailScreen(articleId: a.id)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (a.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text('Unggulan',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(height: 8),
                              Text(a.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text('${a.readTimeMinutes} min baca',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
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

  Widget _sectionHeader(String title, VoidCallback onSeeAll) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
        ],
      );
}
