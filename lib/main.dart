import 'package:auth_modul/screens/home.dart';
import 'package:auth_modul/screens/login.dart';
import 'package:auth_modul/screens/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Forum feature imports
import 'features/repositories/forum_repository.dart';
import 'features/forum/forum_provider.dart';
import 'features/screens/forum_feed_screen.dart';
import 'features/screens/post_question_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ForumRepository()),
        ChangeNotifierProvider(
          create: (context) => ForumProvider(
            context.read<ForumRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Discussion Forum',
      initialRoute: 'login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routes: {
        'home': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'forum': (context) => const ForumFeedScreen(),
        'post_question': (context) => const PostQuestionScreen(),
      },
    );
  }
}
