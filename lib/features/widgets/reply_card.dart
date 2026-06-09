import 'package:flutter/material.dart';
import '../models/reply.dart';

class ReplyCard extends StatelessWidget {
  final Reply reply;

  const ReplyCard({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(
                  reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reply.authorName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_formatTimeAgo(reply.createdAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              reply.content,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays >= 1) return '${duration.inDays}d';
    if (duration.inHours >= 1) return '${duration.inHours}h';
    if (duration.inMinutes >= 1) return '${duration.inMinutes}m';
    return 'now';
  }
}
