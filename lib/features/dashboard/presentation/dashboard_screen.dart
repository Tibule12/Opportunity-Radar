import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/models/earnings_record.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/task_response.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final createdTasksAsync = ref.watch(createdTasksProvider);
    final assignedTasksAsync = ref.watch(assignedTasksProvider);
    final workerResponsesAsync = ref.watch(workerResponsesProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return AppScaffold(
      title: 'Pulse',
      child: profileAsync.when(
        data: (profile) {
          return createdTasksAsync.when(
            data: (createdTasks) {
              return assignedTasksAsync.when(
                data: (assignedTasks) {
                  return workerResponsesAsync.when(
                    data: (workerResponses) {
                      return notificationsAsync.when(
                        data: (notifications) {
                          final snapshot = _DashboardSnapshot(
                            currentUserId: currentUserId,
                            profile: profile,
                            createdTasks: createdTasks,
                            assignedTasks: assignedTasks,
                            workerResponses: workerResponses,
                            notifications: notifications,
                          );

                          return _DashboardContent(snapshot: snapshot);
                        },
                        loading: () => const MarketplaceLoadingState(
                          title: 'Loading dashboard',
                          message: 'Gathering activity, jobs, and response flow for your dashboard.',
                        ),
                        error: (error, _) => _DashboardError(message: '$error'),
                      );
                    },
                    loading: () => const MarketplaceLoadingState(
                      title: 'Loading dashboard',
                      message: 'Gathering activity, jobs, and response flow for your dashboard.',
                    ),
                    error: (error, _) => _DashboardError(message: '$error'),
                  );
                },
                loading: () => const MarketplaceLoadingState(
                  title: 'Loading dashboard',
                  message: 'Gathering activity, jobs, and response flow for your dashboard.',
                ),
                error: (error, _) => _DashboardError(message: '$error'),
              );
            },
            loading: () => const MarketplaceLoadingState(
              title: 'Loading dashboard',
              message: 'Gathering activity, jobs, and response flow for your dashboard.',
            ),
            error: (error, _) => _DashboardError(message: '$error'),
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading dashboard',
          message: 'Gathering activity, jobs, and response flow for your dashboard.',
        ),
        error: (error, _) => _DashboardError(message: '$error'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final _DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final activeCustomerTasks = snapshot.createdTasks
        .where((task) => task.status == 'open' || task.status == 'matched' || task.status == 'in_progress')
        .toList();
    final activeWorkerTasks = snapshot.assignedTasks
        .where((task) => task.status == 'matched' || task.status == 'in_progress')
        .toList();
    final completedWorkerTasks = snapshot.assignedTasks
        .where((task) => task.status == 'completed')
        .toList();
    final pendingResponses = snapshot.workerResponses
        .where((response) => response.status == 'pending')
        .length;
    final acceptedResponses = snapshot.workerResponses
        .where((response) => response.status == 'accepted')
        .length;
    final projectedEarnings = snapshot.assignedTasks
        .where((task) => task.status == 'matched' || task.status == 'in_progress' || task.status == 'completed')
        .fold<double>(0, (sum, task) => sum + task.budgetAmount);
    final unreadCount = snapshot.notifications.where((notification) => !notification.read).length;
    final isWorker = snapshot.profile?.isWorker ?? false;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MomentumBanner(
          snapshot: snapshot,
          activeCustomerTasks: activeCustomerTasks.length,
          activeWorkerTasks: activeWorkerTasks.length,
          unreadCount: unreadCount,
        ),
        if (isWorker && snapshot.profile != null && snapshot.currentUserId != null) ...[
          const SizedBox(height: 18),
          _WorkerModeCard(
            currentUserId: snapshot.currentUserId!,
            profile: snapshot.profile!,
            hasActiveWorkerTask: activeWorkerTasks.isNotEmpty,
          ),
        ],
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 860 ? 4 : 2;
            final childAspectRatio = constraints.maxWidth > 860 ? 1.45 : 1.25;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: childAspectRatio,
              children: [
                _MetricCard(
                  label: 'Active customer tasks',
                  value: '${activeCustomerTasks.length}',
                  footnote: '${snapshot.createdTasks.length} posted total',
                ),
                _MetricCard(
                  label: 'Active worker tasks',
                  value: '${activeWorkerTasks.length}',
                  footnote: '${completedWorkerTasks.length} completed',
                ),
                _MetricCard(
                  label: 'Response pipeline',
                  value: '$pendingResponses',
                  footnote: '$acceptedResponses accepted responses',
                ),
                _MetricCard(
                  label: 'Projected earnings',
                  value: taskCurrencyLabel('ZAR', projectedEarnings),
                  footnote: 'Based on matched and completed jobs',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (isWorker && snapshot.profile != null) ...[
          _WorkerEarningsSummary(profile: snapshot.profile!),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go('/earnings'),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Open full earnings'),
            ),
          ),
          const _WorkerEarningsHistory(),
          const SizedBox(height: 18),
          _ReferralNetworkCard(profile: snapshot.profile!),
          const SizedBox(height: 18),
        ],
        _SectionCard(
          title: 'Account status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Availability',
                value: snapshot.profile == null
                    ? 'Profile incomplete'
                    : _availabilityLabel(snapshot.profile!.availabilityStatus),
              ),
              _DetailRow(
                label: 'Rating',
                value: snapshot.profile == null
                    ? 'No profile yet'
                    : '${snapshot.profile!.ratingAverage.toStringAsFixed(1)} from ${snapshot.profile!.ratingCount} ratings',
              ),
              _DetailRow(
                label: 'Response speed',
                value: snapshot.profile == null
                    ? 'Not enough data'
                    : '${snapshot.profile!.responseSpeedSeconds} sec average',
              ),
              _DetailRow(
                label: 'Unread activity',
                value: '$unreadCount notifications waiting',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _AlertSummaryCard(notifications: snapshot.notifications),
        const SizedBox(height: 18),
        _TaskStrip(
          title: 'Active tasks',
          emptyMessage: 'No matched or in-progress tasks yet. Your next accepted job will land here.',
          tasks: [...activeWorkerTasks, ...activeCustomerTasks].take(5).toList(),
        ),
        const SizedBox(height: 18),
        _RecentActivitySection(notifications: snapshot.notifications),
        if (isWorker) ...[
          const SizedBox(height: 18),
          const _DemandZonesPreviewCard(),
        ],
      ],
    );
  }
}

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.currentUserId,
    required this.profile,
    required this.createdTasks,
    required this.assignedTasks,
    required this.workerResponses,
    required this.notifications,
  });

  final String? currentUserId;
  final UserProfile? profile;
  final List<TaskOpportunity> createdTasks;
  final List<TaskOpportunity> assignedTasks;
  final List<TaskResponse> workerResponses;
  final List<AppNotification> notifications;
}

class _MomentumBanner extends StatelessWidget {
  const _MomentumBanner({
    required this.snapshot,
    required this.activeCustomerTasks,
    required this.activeWorkerTasks,
    required this.unreadCount,
  });

  final _DashboardSnapshot snapshot;
  final int activeCustomerTasks;
  final int activeWorkerTasks;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final displayName = snapshot.profile?.displayName.trim();
    final headline = displayName == null || displayName.isEmpty
        ? 'Your market pulse'
        : 'Your market pulse, $displayName';
    final summary = activeCustomerTasks == 0 && activeWorkerTasks == 0
        ? 'You do not have any active marketplace flow yet. Post a task or respond to one to start momentum.'
        : '$activeCustomerTasks customer tasks and $activeWorkerTasks worker jobs are currently in motion. $unreadCount fresh updates are waiting.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C6B60), Color(0xFF14A38D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
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

class _WorkerModeCard extends ConsumerStatefulWidget {
  const _WorkerModeCard({
    required this.currentUserId,
    required this.profile,
    required this.hasActiveWorkerTask,
  });

  final String currentUserId;
  final UserProfile profile;
  final bool hasActiveWorkerTask;

  @override
  ConsumerState<_WorkerModeCard> createState() => _WorkerModeCardState();
}

class _WorkerModeCardState extends ConsumerState<_WorkerModeCard> {
  StreamSubscription<AppLocation>? _locationSubscription;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPresence();
    });
  }

  @override
  void didUpdateWidget(covariant _WorkerModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.availabilityStatus != widget.profile.availabilityStatus ||
        oldWidget.hasActiveWorkerTask != widget.hasActiveWorkerTask) {
      _syncPresence();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.hasActiveWorkerTask ? 'busy' : widget.profile.availabilityStatus;
    final isOnline = status == 'online';
    final isBusy = status == 'busy';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isBusy
              ? const [Color(0xFF92400E), Color(0xFFD97706)]
              : isOnline
                  ? const [Color(0xFF0C6B60), Color(0xFF14A38D)]
                  : const [Color(0xFF374151), Color(0xFF111827)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worker mode',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Status: ${status.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBusy
                ? 'You are busy on an active task. Nearby alerts are paused until the job is finished.'
                : isOnline
                    ? 'Listening for nearby opportunities and tracking your worker location.'
                    : 'You are offline and will not receive nearby opportunity alerts.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isBusy
                    ? const Color(0xFF92400E)
                    : isOnline
                        ? const Color(0xFF0C6B60)
                        : const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: (_isUpdating || isBusy)
                  ? null
                  : () => isOnline ? _goOffline() : _goOnline(),
              child: Text(
                isBusy
                    ? 'BUSY ON TASK'
                    : isOnline
                        ? 'GO OFFLINE'
                        : 'GO ONLINE',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncPresence() async {
    if (!mounted) {
      return;
    }

    if (widget.hasActiveWorkerTask) {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      if (widget.profile.availabilityStatus != 'busy') {
        await ref.read(userProfileRepositoryProvider).updateWorkerStatus(
              uid: widget.currentUserId,
              workerStatus: 'busy',
            );
      }
      return;
    }

    if (widget.profile.availabilityStatus == 'online' && _locationSubscription == null) {
      await _startTracking();
    }

    if (widget.profile.availabilityStatus != 'online') {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
    }
  }

  Future<void> _goOnline() async {
    setState(() {
      _isUpdating = true;
    });
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      await ref.read(userProfileRepositoryProvider).updateWorkerStatus(
            uid: widget.currentUserId,
            workerStatus: 'online',
            locationAddress: location.addressText ?? widget.profile.locationAddress,
            locationLat: location.latitude,
            locationLng: location.longitude,
          );
      await _startTracking();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _goOffline() async {
    setState(() {
      _isUpdating = true;
    });
    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      await ref.read(userProfileRepositoryProvider).updateWorkerStatus(
            uid: widget.currentUserId,
            workerStatus: 'offline',
          );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _startTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = ref.read(locationServiceProvider).liveLocationStream().listen((location) async {
      await ref.read(userProfileRepositoryProvider).updateWorkerStatus(
            uid: widget.currentUserId,
            workerStatus: 'online',
            locationAddress: location.addressText ?? widget.profile.locationAddress,
            locationLat: location.latitude,
            locationLng: location.longitude,
          );
    });
  }
}

class _WorkerEarningsSummary extends StatelessWidget {
  const _WorkerEarningsSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Earnings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'These figures are informational only. Customers and workers settle payment directly outside the app during MVP.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 760 ? 4 : 2;
              final childAspectRatio = constraints.maxWidth > 760 ? 1.3 : 1.2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: [
                  _MetricCard(
                    label: 'Today',
                    value: taskCurrencyLabel('ZAR', profile.earningsToday),
                    footnote: 'Completed today',
                  ),
                  _MetricCard(
                    label: 'This week',
                    value: taskCurrencyLabel('ZAR', profile.earningsWeek),
                    footnote: 'Rolling 7-day total',
                  ),
                  _MetricCard(
                    label: 'This month',
                    value: taskCurrencyLabel('ZAR', profile.earningsMonth),
                    footnote: 'Rolling 30-day total',
                  ),
                  _MetricCard(
                    label: 'Lifetime',
                    value: taskCurrencyLabel('ZAR', profile.earningsLifetime),
                    footnote: 'All completed tasks',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkerEarningsHistory extends ConsumerWidget {
  const _WorkerEarningsHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(workerEarningsRecordsProvider);
    return _SectionCard(
      title: 'Earnings history',
      child: earningsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Text('Completed worker tasks will appear here once you start closing jobs.');
          }

          return Column(
            children: [
              for (var index = 0; index < records.take(6).length; index++) ...[
                _EarningsHistoryTile(record: records[index]),
                if (index < records.take(6).length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading earnings records',
          message: 'Pulling your completed task values and completion timestamps.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Earnings history unavailable',
          message: 'Failed to load earnings records: $error',
          icon: Icons.payments_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _EarningsHistoryTile extends StatelessWidget {
  const _EarningsHistoryTile({required this.record});

  final EarningsRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task ${record.taskId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.completedAt == null
                      ? 'Completed recently'
                      : taskRelativeTimeLabel(record.completedAt).replaceFirst('Posted ', 'Completed '),
                ),
                const SizedBox(height: 4),
                const Text('Settled directly between customer and worker'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            taskCurrencyLabel('ZAR', record.agreedAmount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReferralNetworkCard extends ConsumerWidget {
  const _ReferralNetworkCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referredWorkersAsync = ref.watch(referredWorkersProvider);

    return _SectionCard(
      title: 'My network',
      child: referredWorkersAsync.when(
        data: (workers) {
          final completedTasksFromNetwork = workers.fold<int>(
            0,
            (sum, worker) => sum + worker.completedTaskCount,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Referral code', value: profile.referralCode),
              _DetailRow(label: 'Invited workers', value: '${workers.length}'),
              _DetailRow(label: 'Completed tasks from network', value: '$completedTasksFromNetwork'),
              _DetailRow(label: 'Rewards earned', value: '${profile.rewardPoints}'),
              if (workers.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var index = 0; index < workers.take(3).length; index++) ...[
                  _NetworkWorkerTile(worker: workers[index]),
                  if (index < workers.take(3).length - 1) const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading network',
          message: 'Pulling referral activity and completed work from your network.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Network unavailable',
          message: 'Failed to load your referral network: $error',
          icon: Icons.group_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _NetworkWorkerTile extends StatelessWidget {
  const _NetworkWorkerTile({required this.worker});

  final UserProfile worker;

  @override
  Widget build(BuildContext context) {
    final name = worker.displayName.trim().isEmpty ? worker.phoneNumber : worker.displayName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(worker.initials),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${worker.completedTaskCount} completed tasks • ${_availabilityLabel(worker.availabilityStatus)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandZonesPreviewCard extends StatelessWidget {
  const _DemandZonesPreviewCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Demand zones',
      child: const Text(
        'Demand-zone guidance is reserved for the next phase. Once density data is live, workers will see high-demand area suggestions here.',
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.footnote,
    this.tint,
  });

  final String label;
  final String value;
  final String footnote;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 6,
              decoration: BoxDecoration(
                color: tint ?? Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(label),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              footnote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TaskStrip extends StatelessWidget {
  const _TaskStrip({
    required this.title,
    required this.tasks,
    required this.emptyMessage,
  });

  final String title;
  final List<TaskOpportunity> tasks;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: tasks.isEmpty
          ? Text(emptyMessage)
          : Column(
              children: [
                for (var index = 0; index < tasks.length; index++) ...[
                  _TaskStripTile(task: tasks[index]),
                  if (index < tasks.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  const _AlertSummaryCard({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final unreadAlerts = notifications.where((notification) => !notification.read).toList();
    final urgentAlerts = unreadAlerts.where(
      (notification) => notification.type == 'task_urgency' || notification.type == 'distribution_expanded',
    ).length;
    final referralAlerts = unreadAlerts.where(
      (notification) => notification.type == 'referral_reward',
    ).length;
    final radarAlerts = unreadAlerts.where(
      (notification) => notification.type == 'new_task',
    ).length;

    return _SectionCard(
      title: 'Alert center',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _AlertChip(
            icon: Icons.radar_outlined,
            label: 'Radar alerts',
            value: '$radarAlerts',
          ),
          _AlertChip(
            icon: Icons.priority_high_outlined,
            label: 'Urgent follow-ups',
            value: '$urgentAlerts',
          ),
          _AlertChip(
            icon: Icons.card_giftcard_outlined,
            label: 'Referral rewards',
            value: '$referralAlerts',
          ),
        ],
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 172),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStripTile extends StatelessWidget {
  const _TaskStripTile({required this.task});

  final TaskOpportunity task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go('/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(task.locationAddress),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(task.status.toUpperCase()),
                const SizedBox(height: 4),
                Text(taskCurrencyLabel(task.currency, task.budgetAmount)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent updates',
      child: notifications.isEmpty
          ? const MarketplaceStatusCard(
              title: 'No updates yet',
              message: 'When tasks, chats, and matches start moving, the latest changes will show up here.',
              icon: Icons.notifications_none_outlined,
            )
          : Column(
              children: [
                for (var index = 0; index < notifications.take(4).length; index++) ...[
                  _RecentActivityTile(notification: notifications[index]),
                  if (index < notifications.take(4).length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: notification.read
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(notification.body),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            taskRelativeTimeLabel(notification.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MarketplaceStatusCard(
      title: 'Dashboard unavailable',
      message: 'Failed to load dashboard: $message',
      icon: Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
      tint: Theme.of(context).colorScheme.error,
    );
  }
}

String _availabilityLabel(String value) {
  switch (value) {
    case 'online':
      return 'Online and listening';
    case 'busy':
      return 'Busy on an active task';
    default:
      return 'Offline';
  }
}
