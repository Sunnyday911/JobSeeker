import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jobseeker/features/repositories/forum_repository.dart';
import 'package:jobseeker/features/forum/forum_provider.dart';
import 'package:jobseeker/features/repositories/notification_repository.dart';
import 'package:jobseeker/features/notifications/notification_provider.dart';
import 'package:jobseeker/features/notifications/notification_service.dart';
import 'package:jobseeker/features/home/main_screen.dart';
import 'package:jobseeker/screens/login_screen.dart';
import 'package:jobseeker/screens/register_screen.dart';
import 'package:jobseeker/screens/forum_feed_screen.dart';
import 'package:jobseeker/screens/post_question_screen.dart';
import 'package:jobseeker/screens/notifications_screen.dart';
import 'package:jobseeker/core/auth_gate.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize(
    navigatorKey,
  );

  runApp(
    MultiProvider(
      providers: [
        // Forum
        Provider(
          create: (_) => ForumRepository(),
        ),

        ChangeNotifierProvider(
          create: (context) => ForumProvider(
            context.read<ForumRepository>(),
          ),
        ),

        // Notifications
        Provider(
          create: (_) => NotificationRepository(),
        ),

        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            context.read<NotificationRepository>(),
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
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      home: const AuthGate(),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      routes: {
        'register': (context) => const RegisterScreen(),
        'forum': (context) => const ForumFeedScreen(),
        'post_question': (context) => const PostQuestionScreen(),
        'notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}