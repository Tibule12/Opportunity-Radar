import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/utils/distance_utils.dart';
import '../../../shared/utils/opportunity_visibility.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';
import '../../../shared/widgets/task_expiry_badge.dart';

class OpportunityFeedScreen extends ConsumerWidget {
  const OpportunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final openTasks = ref.watch(openTasksProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isWorker = currentProfile?.roles.contains('worker') ?? false;
    final workerUnavailable = isWorker && currentProfile?.availabilityStatus != 'online';

    return AppScaffold(
      title: 'Opportunity Radar',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/post-task'),
        icon: const Icon(Icons.add),
        label: const Text('Post Task'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatusBanner(
            displayName: currentProfile?.displayName,
            opportunityCount: visibleTasksForProfile(
              tasks: openTasks.valueOrNull ?? const [],
              currentProfile: currentProfile,
              currentUserId: currentUserId,
            ).length,
            availabilityStatus: currentProfile?.availabilityStatus,
            workerUnavailable: workerUnavailable,
          ),
          const SizedBox(height: 14),
          _FeedInsightStrip(
            workerUnavailable: workerUnavailable,
            isWorker: isWorker,
            visibleOpportunityCount: visibleTasksForProfile(
              tasks: openTasks.valueOrNull ?? const [],
              currentProfile: currentProfile,
              currentUserId: currentUserId,
            ).length,
          ),
          const SizedBox(height: 20),
          openTasks.when(
            data: (tasks) {
              final visibleTasks = visibleTasksForProfile(
                tasks: tasks,
                currentProfile: currentProfile,
                currentUserId: currentUserId,
              );

              if (visibleTasks.isEmpty) {
                return _EmptyFeedState(workerUnavailable: workerUnavailable);
              }

              return Column(
                children: [
                  for (var index = 0; index < visibleTasks.length; index++) ...[
                    _OpportunityCard(
                      task: visibleTasks[index],
                      isOwnTask: currentUserId != null && visibleTasks[index].isOwnedBy(currentUserId),
                      workerProfile: currentProfile,
                    ),
                    if (index < visibleTasks.length - 1) const SizedBox(height: 16),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 32),
              child: MarketplaceLoadingState(
                title: 'Loading opportunities',
                message: 'Refreshing nearby work and live task activity.',
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 24),
              child: MarketplaceStatusCard(
                title: 'Feed unavailable',
                message: 'Failed to load opportunities: $error',
                icon: Icons.radar_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    this.displayName,
    required this.opportunityCount,
    required this.availabilityStatus,
    required this.workerUnavailable,
  });

  final String? displayName;
  final int opportunityCount;
  final String? availabilityStatus;
  final bool workerUnavailable;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7A6D), Color(0xFF149E87), Color(0xFF1DAB8D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220E7A6D),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Live marketplace',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name == null || name.isEmpty ? 'You are online' : 'You are online, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workerUnavailable
              ? 'Your worker mode is ${availabilityStatus?.toUpperCase() ?? 'OFFLINE'}. Use Go Online on the dashboard to receive nearby jobs.'
              : opportunityCount == 0
                ? 'No open opportunities yet. Post a task or wait for the next live request.'
                : '$opportunityCount open opportunities are in the live feed right now.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FeedInsightStrip extends StatelessWidget {
  const _FeedInsightStrip({
    required this.workerUnavailable,
    required this.isWorker,
    required this.visibleOpportunityCount,
  });

  final bool workerUnavailable;
  final bool isWorker;
  final int visibleOpportunityCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InsightPill(
          icon: Icons.flash_on_outlined,
          label: '$visibleOpportunityCount visible now',
        ),
        _InsightPill(
          icon: isWorker && !workerUnavailable ? Icons.radar_outlined : Icons.lock_clock_outlined,
          label: workerUnavailable ? 'Discovery limited' : 'Fast local matching',
        ),
        const _InsightPill(
          icon: Icons.route_outlined,
          label: 'Sorted by distance and freshness',
        ),
      ],
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState({required this.workerUnavailable});

  final bool workerUnavailable;

  @override
  Widget build(BuildContext context) {
    return MarketplaceStatusCard(
      title: 'The feed is quiet right now',
      message: workerUnavailable
          ? 'You are not online yet, so only your own tasks remain visible here.'
          : 'Create the first task in this area or keep the app open while new opportunities arrive.',
      icon: workerUnavailable ? Icons.lock_clock_outlined : Icons.radar_outlined,
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.task,
    required this.isOwnTask,
    required this.workerProfile,
  });

  final TaskOpportunity task;
  final bool isOwnTask;
  final UserProfile? workerProfile;

  @override
  Widget build(BuildContext context) {
    final distanceKm = distanceFromProfile(workerProfile, task);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(_categoryLabel(task.category))),
                      if (isOwnTask) const Chip(label: Text('Your task')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _currencyLabel(task.currency, task.budgetAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(task.locationAddress)),
              ],
            ),
            if (distanceKm != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(distanceLabelKm(distanceKm)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(taskRelativeTimeLabel(task.createdAt)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TaskExpiryBadge(expiresAt: task.expiresAt),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups_2_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${task.responseCount} worker responses so far')),
                  Text(
                    task.status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/tasks/${task.id}'),
              child: const Text('View task'),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(String value) {
  switch (value) {
    case 'delivery':
      return 'Delivery';
    case 'transport':
      return 'Transport';
    case 'errands':
      return 'Errands';
    case 'moving_help':
      return 'Moving Help';
    default:
      return 'Other';
  }
}

String _currencyLabel(String currency, double amount) {
  return taskCurrencyLabel(currency, amount);
}
