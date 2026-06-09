// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:jobseeker/screens/login_screen.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   void logout(BuildContext context) async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.pushReplacementNamed(context, 'login');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (snapshot.hasData) {
//           return Scaffold(
//             appBar: AppBar(
//               title: const Text('Career Discussion'),
//               actions: [
//                 IconButton(
//                   onPressed: () => Navigator.pushNamed(context, 'forum'),
//                   icon: const Icon(Icons.forum_outlined),
//                 ),
//                 IconButton(
//                   onPressed: () => logout(context),
//                   icon: const Icon(Icons.logout),
//                 ),
//               ],
//             ),
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Welcome, ${snapshot.data?.displayName ?? snapshot.data?.email}'),
//                   const SizedBox(height: 24),
//                   FilledButton(
//                     onPressed: () => Navigator.pushNamed(context, 'forum'),
//                     child: const Text('Go to Forum'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         } else {
//           return const LoginScreen();
//         }
//       },
//     );
//   }
// }
