import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobSeeker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Muiz 👋',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find your dream job',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search jobs, companies, locations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CategoryPill(icon: Icons.code, label: 'Tech'),
                    SizedBox(width: 10),
                    _CategoryPill(icon: Icons.brush_outlined, label: 'Design'),
                    SizedBox(width: 10),
                    _CategoryPill(icon: Icons.campaign_outlined, label: 'Marketing'),
                    SizedBox(width: 10),
                    _CategoryPill(icon: Icons.attach_money, label: 'Finance'),
                    SizedBox(width: 10),
                    _CategoryPill(icon: Icons.medical_services_outlined, label: 'Healthcare'),
                    SizedBox(width: 10),
                    _CategoryPill(icon: Icons.school_outlined, label: 'Education'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured jobs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text('See all'),
                ],
              ),
              const SizedBox(height: 12),
              const _JobCard(
                title: 'Senior Flutter Developer',
                company: 'Nimbus Labs',
                location: 'Jakarta, Indonesia (Remote)',
                salary: 'Rp 25 - 35 jt/mo',
                type: 'Full-time',
                postedAgo: '2d ago',
              ),
              const _JobCard(
                title: 'Product Designer',
                company: 'Pixel & Co.',
                location: 'Bandung, Indonesia',
                salary: 'Rp 15 - 22 jt/mo',
                type: 'Full-time',
                postedAgo: '5h ago',
              ),
              const _JobCard(
                title: 'Growth Marketing Lead',
                company: 'Tumbuh.id',
                location: 'Remote',
                salary: 'Rp 20 - 30 jt/mo',
                type: 'Contract',
                postedAgo: '1d ago',
              ),
              const _JobCard(
                title: 'Financial Analyst',
                company: 'Mandala Capital',
                location: 'Jakarta, Indonesia',
                salary: 'Rp 12 - 18 jt/mo',
                type: 'Full-time',
                postedAgo: '3d ago',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type;
  final String postedAgo;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.type,
    required this.postedAgo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initial = company.isNotEmpty ? company[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.bookmark_border),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                salary,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                postedAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
