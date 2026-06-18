import 'package:flutter/material.dart';
import 'package:jobseeker/features/articles/articles_feed_screen.dart';
import 'package:jobseeker/features/bookmarks/bookmarks_screen.dart';
import 'package:jobseeker/features/profile/profile_screen.dart';
import 'package:jobseeker/features/jobs/jobs_screen.dart';

/// CareerCompass shell: Home (articles + news) / Bookmarks / Profile.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const ArticlesFeedScreen(),
    BookmarksScreen(),
    const JobsScreen(),
    const ProfileScreen(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmark'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Job'),
          // BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
