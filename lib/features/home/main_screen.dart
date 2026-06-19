import 'package:flutter/material.dart';
import 'package:jobseeker/features/articles/articles_feed_screen.dart';
import 'package:jobseeker/features/bookmarks/bookmarks_screen.dart';
import 'package:jobseeker/features/profile/profile_screen.dart';
import 'package:jobseeker/features/jobs/jobs_screen.dart';

import 'package:jobseeker/screens/forum_feed_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const ArticlesFeedScreen(),
    const ForumFeedScreen(),
    BookmarksScreen(),
    const JobsScreen(),
    const ProfileScreen(),

  ];

  String get _title {
    switch (_currentIndex) {
      case 0:
        return 'CareerCompass';
      case 1:
        return 'Forum';
      case 2:
        return 'Bookmarks';
      case 3:
        return 'Profile';
      default:
        return 'CareerCompass';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.pushNamed(
                context,
                'notifications',
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Tersimpan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
      ),
    );
  }
}