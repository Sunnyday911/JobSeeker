import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jobseeker/features/models/question.dart';
import 'package:jobseeker/features/widgets/question_card.dart';
import 'package:jobseeker/features/forum/forum_provider.dart';
import 'question_details_screen.dart';

class ForumFeedScreen extends StatefulWidget {
  const ForumFeedScreen({super.key});

  @override
  State<ForumFeedScreen> createState() => _ForumFeedScreenState();
}

class _ForumFeedScreenState extends State<ForumFeedScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Terbaru'; // Terbaru | Paling Dijawab | Trending
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;
  final _scrollController = ScrollController();

  final List<String> _categories = [
    'All',
    'Advice',
    'Interview',
    'Salary',
    'Tech',
    'Remote Work'
  ];
  final List<String> _sortOptions = ['Terbaru', 'Paling Dijawab', 'Trending'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Infinite scroll: reveal another page when near the bottom (US16.6).
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  List<Question> _sorted(List<Question> qs) {
    final list = [...qs];
    switch (_sortBy) {
      case 'Paling Dijawab':
        list.sort((a, b) => b.replyCount.compareTo(a.replyCount));
        break;
      case 'Trending':
        int score(Question q) => q.upvotes * 2 + q.replyCount * 3;
        list.sort((a, b) => score(b).compareTo(score(a)));
        break;
      default: // Terbaru
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Forum'),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              hintText: 'Search discussions...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selectedColor: theme.colorScheme.primary,
                );
              },
            ),
          ),
          // Sort selector (US16.3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.sort, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Urutkan:', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox.shrink(),
                  items: _sortOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _sortBy = v ?? 'Terbaru';
                    _visibleCount = _pageSize;
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Feed
          Expanded(
            child: Consumer<ForumProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.questions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.questions.isEmpty) {
                  return _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadQuestions(),
                  );
                }

                // Filtering logic
                final filteredQuestions = provider.questions.where((q) {
                  final matchesSearch = q.title.toLowerCase().contains(_searchQuery) ||
                      q.content.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == 'All' || q.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredQuestions.isEmpty) {
                  return const _EmptyState();
                }

                // Sort (US16.3) then page client-side 15-at-a-time (US16.6).
                final sorted = _sorted(filteredQuestions);
                final visible = sorted.take(_visibleCount).toList();
                final hasMore = _visibleCount < sorted.length;

                return RefreshIndicator(
                  onRefresh: () async => provider.loadQuestions(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: visible.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= visible.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final question = visible[index];
                      return QuestionCard(
                        question: question,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionDetailsScreen(question: question),
                            ),
                          );
                        },
                        onUpvote: () {
                          provider.upvoteQuestion(question.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, 'post_question'),
        label: const Text('Ask Question'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No discussions found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Be the first to ask a question!'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
