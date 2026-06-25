import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../features/notifications/notification_provider.dart';
import '../features/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => provider.markAllAsRead(),
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          print(
            'NotificationsScreen sees ${provider.notifications.length} notifications',
          );
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when something happens',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // The stream handles updates, but we can re-trigger if needed
            },
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.read<NotificationProvider>();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: ListTile(
        onTap: () {
          if (!notification.read) {
            provider.markAsRead(notification.id);
          }
          if (notification.route != null && notification.route!.isNotEmpty) {
            Navigator.pushNamed(context, notification.route!);
          }
        },
        leading: CircleAvatar(
          backgroundColor: notification.read
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          child: Icon(
            notification.read
                ? Icons.notifications_outlined
                : Icons.notifications_active,
            color: notification.read
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: notification.read
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        tileColor: notification.read ? null : colorScheme.primaryContainer.withValues(alpha: 0.1),
      ),
    );
  }
}
