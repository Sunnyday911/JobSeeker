import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;

  const NotificationListenerWidget({
    super.key,
    required this.child,
  });

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState
    extends State<NotificationListenerWidget> {

  String? _lastNotificationId;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {

        if (provider.notifications.isNotEmpty) {
          final newest = provider.notifications.first;

          if (_lastNotificationId != null &&
              newest.id != _lastNotificationId &&
              !newest.read) {

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newest.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(newest.body),
                    ],
                  ),
                ),
              );
            });
          }

          _lastNotificationId = newest.id;
        }

        return widget.child;
      },
    );
  }
}