import 'package:flutter/material.dart';

// --- Import dari branch epic-alfa (Auth) ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:auth_modul/screens/home.dart';
import 'package:auth_modul/screens/login.dart';
import 'package:auth_modul/screens/register.dart';

// --- Import dari branch kamu (UI Shell) ---
import 'features/home/main_screen.dart';
import 'features/Opportunities/opportunities_screen.dart';

void main() async {
  // 1. Mempertahankan inisialisasi Firebase dari branch epic-alfa
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Menjalankan class aplikasi utama kita
  runApp(const OpportuLinkApp());
}

class OpportuLinkApp extends StatelessWidget {
  const OpportuLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpportuLink',
      debugShowCheckedModeBanner: false,
      
      // 3. Mempertahankan Tema Desain dari branch main
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50], 
        fontFamily: 'Roboto', 
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      
      // 4. Menggabungkan sistem Routing dari branch epic-alfa
      // Aplikasi akan dibuka pertama kali di halaman Login
      initialRoute: 'login', 
      routes: {
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        // PENTING: Arahkan rute 'home' ke MainScreen (Bottom Nav Bar) buatanmu,
        // supaya setelah login sukses, user masuk ke dashboard utama OpportuLink.
        'home': (context) => const MainScreen(), 
      },
    );
  }
}