import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/cv_profile.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/models/job_recommendation.dart';
import 'package:jobseeker/features/repositories/cv_repository.dart';
import 'package:jobseeker/features/services/adzuna_service.dart';
import 'package:jobseeker/features/services/claude_service.dart';
import 'package:jobseeker/features/cv/cv_analysis_screen.dart';
import 'package:jobseeker/features/jobs_feed/job_detail_screen.dart';

/// AI job recommendations (US09): ranks Adzuna jobs against the saved CV
/// profile, sorted by match score, with skill gaps. Refreshable.
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _cvRepo = CvRepository();

  bool _loading = true;
  String? _error;
  CvProfile? _profile;
  final Map<String, Job> _jobsById = {};
  List<JobRecommendation> _recs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _cvRepo.getProfile();
      if (profile == null) {
        if (mounted) {
          setState(() {
            _profile = null;
            _loading = false;
          });
        }
        return;
      }
      final query = profile.skills.isNotEmpty ? profile.skills.first : '';
      final jobs = await AdzunaService.instance.searchJobs(what: query);
      final jobsById = {for (final j in jobs) j.id: j};
      final ranked = await ClaudeService.instance.rankJobs(profile, jobs);
      // Enrich with job title/company so the saved recs render on the dashboard.
      final recs = ranked
          .map((r) => r.copyWith(
                jobTitle: jobsById[r.jobId]?.title,
                company: jobsById[r.jobId]?.company,
              ))
          .toList()
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore)); // US09.4
      await _cvRepo.saveRecommendations(recs); // US09.7
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _jobsById
          ..clear()
          ..addEntries(jobs.map((j) => MapEntry(j.id, j)));
        _recs = recs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi AI'),
        actions: [
          IconButton(
            tooltip: 'Edit CV',
            icon: const Icon(Icons.edit_note),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
              );
              _load();
            },
          ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined,
                  size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Belum ada profil CV. Analisis CV kamu dulu untuk '
                'mendapatkan rekomendasi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
                  );
                  _load();
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Analisis CV'),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat rekomendasi.\n$_error',
              textAlign: TextAlign.center),
        ),
      );
    }

    if (_recs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Belum ada rekomendasi.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recs.length,
        itemBuilder: (context, i) {
          final rec = _recs[i];
          final job = _jobsById[rec.jobId];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: job == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: job)),
                      ),
              title: Text(job?.title ?? rec.jobId,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job != null) Text(job.company),
                  if (rec.skillGap.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Skill gap: ${rec.skillGap.join(', ')}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.deepOrange)),
                  ],
                ],
              ),
              isThreeLine: rec.skillGap.isNotEmpty,
              trailing: _matchBadge(rec.matchScore),
            ),
          );
        },
      ),
    );
  }

  Widget _matchBadge(int score) {
    final color =
        score >= 75 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$score%',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
