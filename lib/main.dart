import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Forum feature imports
import 'package:jobseeker/features/repositories/forum_repository.dart';
import 'package:jobseeker/features/forum/forum_provider.dart';

// Screen imports
import 'package:jobseeker/features/home/home_screen.dart';
import 'package:jobseeker/screens/login_screen.dart';
import 'package:jobseeker/screens/register_screen.dart';
import 'package:jobseeker/screens/forum_feed_screen.dart';
import 'package:jobseeker/screens/post_question_screen.dart';

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
