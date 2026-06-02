import 'package:flutter/material.dart';
// Pastikan path import ini sesuai dengan nama project Flutter kamu.
// Kalau nama project-mu opportulink, berarti seperti ini:
// import 'package:opportulink/features/home/presentation/screens/main_screen.dart';
import 'features/home/main_screen.dart';
import 'features/Opportunities/opportunities_screen.dart';

void main() {
  // Kalau nanti ada inisialisasi Firebase, taruhnya di sini sebelum runApp
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(const OpportuLinkApp());
}

class OpportuLinkApp extends StatelessWidget {
  const OpportuLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpportuLink',
      debugShowCheckedModeBanner: false, // Menghilangkan pita "DEBUG" di pojok kanan atas
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50], // Sesuai dengan warna background HomeScreen
        fontFamily: 'Roboto', // Bisa diganti kalau kalian pakai Google Fonts
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      // Mengarahkan aplikasi untuk langsung membuka MainScreen (Bottom Nav Bar)
      home: const MainScreen(),
    );
  }
}