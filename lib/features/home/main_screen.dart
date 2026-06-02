import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import file home kamu nanti

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Nanti index 1, 2, 3, 4 diganti dengan file dari branch temen-temenmu
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text('Opportunities Screen (Coming Soon)')),
    const Center(child: Text('Events Screen (Coming Soon)')),
    const Center(child: Text('Applications Screen (Coming Soon)')),
    const Center(child: Text('Profile Screen (Branch Muiz)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Opportunities'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}