import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jobseeker/features/repositories/forum_repository.dart';
import 'package:jobseeker/features/forum/forum_provider.dart';
import 'package:jobseeker/features/repositories/notification_repository.dart';
import 'package:jobseeker/features/notifications/notification_provider.dart';
import 'package:jobseeker/features/notifications/notification_service.dart';
import 'package:jobseeker/features/notifications/notification_listener.dart';
import 'package:jobseeker/screens/register_screen.dart';
import 'package:jobseeker/screens/forum_feed_screen.dart';
import 'package:jobseeker/screens/post_question_screen.dart';
import 'package:jobseeker/screens/notifications_screen.dart';
import 'package:jobseeker/core/auth_gate.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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

  // Initialize FCM AFTER the first frame and without blocking it. On iOS,
  // awaiting this before runApp() caused a permanent white screen (the iOS
  // permission dialog + getToken() throwing without an APNs token). The call
  // is self-guarded, so failures never take down the UI.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.initialize(navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Discussion Forum',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      home: NotificationListenerWidget(
        child: const AuthGate(),
      ),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      routes: {
        'register': (context) => const RegisterScreen(),
        'post_question': (context) => const PostQuestionScreen(),
        'notifications': (context) => const NotificationsScreen(),
        'forum': (context) => const ForumFeedScreen(),
      },
    );
  }
}