import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppScaffold(
      title: 'Notifications',
      actions: [
        if (unreadCount > 0)
          IconButton(
            onPressed: notificationsAsync.valueOrNull == null
                ? null
                : () async {
                    final unreadIds = notificationsAsync.valueOrNull!
                        .where((notification) => !notification.read)
                        .map((notification) => notification.id)
                        .toList();
                    await ref.read(notificationRepositoryProvider).markAllAsRead(unreadIds);
                    if (context.mounted) {
                      showMarketplaceMessage(context, 'All activity marked as read.');
                    }
                  },
            icon: const Icon(Icons.done_all_outlined),
            tooltip: 'Mark all read',
          ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _NotificationSummaryCard(unreadCount: unreadCount),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('All activity'),
                  selected: !_showUnreadOnly,
                  onSelected: (_) {
                    setState(() {
                      _showUnreadOnly = false;
                    });
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text('Unread ($unreadCount)'),
                  selected: _showUnreadOnly,
                  onSelected: (_) {
                    setState(() {
                      _showUnreadOnly = true;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final visibleNotifications = _showUnreadOnly
                    ? notifications.where((notification) => !notification.read).toList()
                    : notifications;

                if (visibleNotifications.isEmpty) {
                  return MarketplaceStatusCard(
                    title: _showUnreadOnly ? 'Inbox cleared' : 'No activity yet',
                    message: _showUnreadOnly
                        ? 'There are no unread updates right now.'
                        : 'Marketplace activity will appear here as tasks, chats, and matches move.',
                    icon: _showUnreadOnly
                        ? Icons.mark_email_read_outlined
                        : Icons.notifications_none_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: visibleNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = visibleNotifications[index];
                    return _NotificationTile(notification: notification);
                  },
                );
              },
              loading: () => const MarketplaceLoadingState(
                title: 'Loading activity',
                message: 'Pulling your latest alerts, matches, and task updates.',
              ),
              error: (error, _) => MarketplaceStatusCard(
                title: 'Activity unavailable',
                message: 'Failed to load activity: $error',
                icon: Icons.notifications_active_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = _colorForType(context, notification.type);
    final canOpenTask = (notification.taskId ?? '').trim().isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          if (!notification.read) {
            await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          }

          if (context.mounted && canOpenTask) {
            context.go('/tasks/${notification.taskId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notification.body),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            taskRelativeTimeLabel(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (canOpenTask)
                          Text(
                            'View task',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_task':
        return Icons.radar_outlined;
      case 'distribution_expanded':
        return Icons.track_changes_outlined;
      case 'task_urgency':
        return Icons.priority_high_outlined;
      case 'referral_reward':
        return Icons.card_giftcard_outlined;
      case 'task_response':
        return Icons.groups_2_outlined;
      case 'task_selected':
        return Icons.check_circle_outline;
      case 'task_message':
        return Icons.chat_bubble_outline;
      case 'task_in_progress':
        return Icons.directions_run_outlined;
      case 'task_completed':
        return Icons.flag_outlined;
      case 'task_expired':
        return Icons.hourglass_disabled_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    switch (type) {
      case 'task_selected':
      case 'task_completed':
      case 'referral_reward':
        return const Color(0xFF0E7A6D);
      case 'task_message':
        return const Color(0xFF2563EB);
      case 'task_response':
      case 'new_task':
      case 'distribution_expanded':
        return const Color(0xFFF59E0B);
      case 'task_expired':
      case 'task_urgency':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  const _NotificationSummaryCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28536B), Color(0xFF0E7A6D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity center',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unreadCount == 0
                ? 'You are fully caught up across matches, chats, and marketplace movement.'
                : '$unreadCount updates still need your attention.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}