import 'package:flutter/material.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/services/adzuna_service.dart';
import 'package:jobseeker/features/jobs_feed/job_detail_screen.dart';
import 'package:jobseeker/features/jobs_feed/saved_jobs_screen.dart';
import 'package:jobseeker/features/cv/recommendations_screen.dart';
import 'package:jobseeker/features/applications/my_applications_screen.dart';
import 'package:jobseeker/features/jobs/jobs_screen.dart';
import 'package:jobseeker/features/jobs/add_jobs_screen.dart';
import 'package:jobseeker/features/models/app_user.dart';
import 'package:jobseeker/features/repositories/user_repository.dart';

/// Adzuna job feed with search + filters + infinite scroll (US04, US05).
class JobsFeedScreen extends StatefulWidget {
  const JobsFeedScreen({super.key});

  @override
  State<JobsFeedScreen> createState() => _JobsFeedScreenState();
}

class _JobsFeedScreenState extends State<JobsFeedScreen> {
  final _adzuna = AdzunaService.instance;
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<Job> _jobs = [];
  String _source = 'adzuna'; // 'adzuna' | 'company'
  AppUser? _profile;
  String _what = '';
  String _where = ''; // location filter (US05.2)
  String? _category; // Adzuna category tag (US05.3)
  String? _contract; // full_time / part_time / contract
  List<({String tag, String label})> _categories = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  bool get _isCompany => _profile?.role == 'company';

  static const Map<String, String?> _contractFilters = {
    'Semua': null,
    'Full-time': 'full_time',
    'Part-time': 'part_time',
    'Kontrak': 'contract',
  };

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(reset: true);
    _loadCategories();
    UserRepository().getCurrentProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _profile = p;
        // Company accounts default to the "Perusahaan" segment (Change Plan
        // 2.0, Part 7.4); the Adzuna seeker feed stays available but secondary.
        if (p?.role == 'company') _source = 'company';
      });
      // Personalize the feed from the profile (Onboarding → Jobs) when the user
      // hasn't searched yet. Industry seeds the Adzuna keyword; city is not used
      // here because Adzuna has no Indonesia index (an Indonesian city query
      // returns nothing) — city personalization belongs to the company jobs.
      final industry = p?.industry;
      if (_what.isEmpty && industry != null && industry.isNotEmpty) {
        setState(() {
          _what = industry;
          _searchCtrl.text = industry;
        });
        _load(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _locationCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_isLoading &&
        _hasMore) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _jobs.clear();
        _page = 1;
        _hasMore = true;
      }
    });
    try {
      final results = await _adzuna.searchJobs(
        what: _what,
        where: _where,
        category: _category,
        contractType: _contract,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _jobs.addAll(results);
        _hasMore = results.isNotEmpty;
        _page += 1;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _what = _searchCtrl.text.trim();
    _where = _locationCtrl.text.trim();
    _load(reset: true);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _adzuna.fetchCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {
      // Keep empty → dropdown shows only "Semua Kategori".
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lowongan Kerja'),
        actions: [
          // Seeker-only shortcuts — hidden for company accounts (Change Plan 2.0).
          if (!_isCompany) ...[
            IconButton(
              tooltip: 'Rekomendasi AI',
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Lamaran Saya',
              icon: const Icon(Icons.assignment_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Tersimpan',
              icon: const Icon(Icons.bookmark),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedJobsScreen()),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: (_source == 'company' && _isCompany)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddJobScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Lowongan'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'adzuna',
                    label: Text('Adzuna'),
                    icon: Icon(Icons.public)),
                ButtonSegment(
                    value: 'company',
                    label: Text('Perusahaan'),
                    icon: Icon(Icons.business)),
              ],
              selected: {_source},
              onSelectionChanged: (s) => setState(() => _source = s.first),
            ),
          ),
          if (_source == 'adzuna') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Cari posisi atau perusahaan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _applyFilters,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Location filter (US05.2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _locationCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Lokasi (kota/provinsi)...',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Category filter (US05.3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<String?>(
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Semua Kategori')),
                  ..._categories.map((c) => DropdownMenuItem<String?>(
                      value: c.tag, child: Text(c.label))),
                ],
                onChanged: (v) {
                  setState(() => _category = v);
                  _load(reset: true); // auto-update on filter (US05.5)
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _contractFilters.entries.map((e) {
                  final selected = _contract == e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(e.key),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _contract = e.value);
                        _load(reset: true); // auto-update on filter (US05.5)
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: _source == 'adzuna'
                ? _buildList()
                : CompanyJobsView(isCompany: _isCompany),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_error != null && _jobs.isEmpty) {
      return _centerMsg('Gagal memuat lowongan.\n$_error');
    }
    if (_isLoading && _jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator()); // US04.5
    }
    if (_jobs.isEmpty) {
      return _centerMsg('Tidak ada lowongan ditemukan.'); // US04.6
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _jobs.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _jobs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = _jobs[i];
          return _JobCard(
            job: job,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            ),
          );
        },
      ),
    );
  }

  Widget _centerMsg(String msg) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: c.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(msg, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      );
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(job.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (job.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(job.category!,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(job.company, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              _iconLine(Icons.location_on_outlined, job.location),
              const SizedBox(height: 4),
              _iconLine(Icons.payments_outlined, job.salaryRange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      );
}
