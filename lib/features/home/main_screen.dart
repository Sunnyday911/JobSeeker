import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jobseeker/features/home/home_dashboard_screen.dart';
import 'package:jobseeker/features/profile/profile_screen.dart';
import 'package:jobseeker/features/jobs_feed/jobs_feed_screen.dart';
import 'package:jobseeker/features/notifications/notification_provider.dart';
import 'package:jobseeker/screens/forum_feed_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeDashboardScreen(onOpenJobsTab: () => setState(() => _currentIndex = 1)),
    const JobsFeedScreen(), // 1 Lowongan (Adzuna + Perusahaan)
    const ForumFeedScreen(), // 2 Forum
    const ProfileScreen(), // 3 Profil
  ];

  static const List<String> _titles = [
    'JobSeeker',
    'Lowongan',
    'Forum',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(_titles[_currentIndex]),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              final count = notif.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.pushNamed(context, 'notifications'),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline), label: 'Lowongan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
