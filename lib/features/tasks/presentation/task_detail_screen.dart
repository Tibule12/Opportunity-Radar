import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/task_message.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/models/task_rating.dart';
import '../../../shared/models/task_response.dart';
import '../../../shared/models/worker_task_location.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';
import '../../../shared/widgets/task_expiry_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return AppScaffold(
      title: 'Task Detail',
      child: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const MarketplaceStatusCard(
              title: 'Task not found',
              message: 'This task is no longer available or the link is out of date.',
              icon: Icons.assignment_late_outlined,
            );
          }

          return _TaskDetailViewRegistrar(task: task);
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading task',
          message: 'Pulling in task details, offers, and live participant activity.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Task unavailable',
          message: 'Failed to load task: $error',
          icon: Icons.assignment_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _TaskDetailViewRegistrar extends ConsumerStatefulWidget {
  const _TaskDetailViewRegistrar({required this.task});

  final TaskOpportunity task;

  @override
  ConsumerState<_TaskDetailViewRegistrar> createState() =>
      _TaskDetailViewRegistrarState();
}

class _TaskDetailViewRegistrarState
    extends ConsumerState<_TaskDetailViewRegistrar> {
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registered) {
      return;
    }

    _registered = true;
    Future<void>.microtask(() {
      ref.read(taskRepositoryProvider).registerTaskView(taskId: widget.task.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TaskDetailContent(task: widget.task);
  }
}

class _TaskDetailContent extends ConsumerWidget {
  const _TaskDetailContent({required this.task});

  final TaskOpportunity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final currentUserId = currentUser?.uid;
    final isOwner = currentUserId != null && task.isOwnedBy(currentUserId);
    final canChat = currentUserId != null &&
        task.assignedWorkerId != null &&
        (isOwner || task.assignedWorkerId == currentUserId);
    final responsesAsync = ref.watch(taskResponsesProvider(task.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TaskHeroCard(task: task, isOwner: isOwner),
        if (isOwner) ...[
          const SizedBox(height: 20),
          _CustomerSearchPanel(task: task),
        ],
        const SizedBox(height: 20),
        if (!isOwner && currentUserId != null && task.assignedWorkerId == null)
          _WorkerResponseComposer(task: task, workerId: currentUserId),
        if (!isOwner && currentUserId != null && task.assignedWorkerId == currentUserId)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('You have been selected for this task.'),
            ),
          ),
        if (currentUserId != null)
          _TaskStatusActions(
            task: task,
            currentUserId: currentUserId,
            isOwner: isOwner,
          ),
        if (currentUserId != null && isOwner && task.assignedWorkerId != null)
          _TrustedWorkerActionCard(
            ownerUserId: currentUserId,
            task: task,
          ),
        if (currentUserId != null && task.assignedWorkerId != null)
          _WorkerLiveLocationPanel(
            task: task,
            currentUserId: currentUserId,
            isOwner: isOwner,
          ),
        if (canChat) ...[
          const SizedBox(height: 20),
          _TaskChatPanel(
            task: task,
            currentUserId: currentUserId,
          ),
        ],
        if (currentUserId != null && task.status == 'completed') ...[
          const SizedBox(height: 20),
          const _CompletionPaymentNotice(),
          const SizedBox(height: 20),
          _TaskRatingPanel(
            task: task,
            currentUserId: currentUserId,
            isOwner: isOwner,
          ),
        ],
        const SizedBox(height: 20),
        _SectionHeading(
          title: isOwner ? 'Worker responses' : 'Responses',
          subtitle: task.responseCount == 0
              ? 'No offers have landed yet.'
              : '${task.responseCount} response${task.responseCount == 1 ? '' : 's'} in the pipeline.',
        ),
        const SizedBox(height: 12),
        responsesAsync.when(
          data: (responses) {
            if (responses.isEmpty) {
              return const MarketplaceStatusCard(
                title: 'No responses yet',
                message: 'Worker offers will appear here as soon as someone replies to this task.',
                icon: Icons.groups_2_outlined,
              );
            }

            return Column(
              children: [
                for (var index = 0; index < responses.length; index++) ...[
                  _ResponseCard(
                    task: task,
                    response: responses[index],
                    isOwner: isOwner,
                    currentUserId: currentUserId,
                  ),
                  if (index < responses.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: MarketplaceLoadingState(
              title: 'Loading responses',
              message: 'Checking for new worker offers and selection updates.',
            ),
          ),
          error: (error, _) => MarketplaceStatusCard(
            title: 'Responses unavailable',
            message: 'Failed to load responses: $error',
            icon: Icons.groups_2_outlined,
            tint: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  const _TaskHeroCard({
    required this.task,
    required this.isOwner,
  });

  final TaskOpportunity task;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13231F), Color(0xFF0E7A6D), Color(0xFF1B8D79)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2213231F),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroTag(label: taskCategoryLabel(task.category)),
              _HeroTag(label: task.status.toUpperCase()),
              if (isOwner) const _HeroTag(label: 'Your task'),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TaskExpiryBadge(expiresAt: task.expiresAt),
          ),
          const SizedBox(height: 18),
          Text(
            task.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            task.description,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStat(
                label: 'Budget',
                value: taskCurrencyLabel(task.currency, task.budgetAmount),
              ),
              _HeroStat(
                label: 'Location',
                value: task.locationAddress,
              ),
              _HeroStat(
                label: 'Posted',
                value: taskRelativeTimeLabel(task.createdAt).replaceFirst('Posted ', ''),
              ),
              _HeroStat(
                label: 'Expires',
                value: taskExpiryLabel(task.expiresAt),
              ),
              _HeroStat(
                label: 'Views',
                value: '${task.viewCount}',
              ),
              _HeroStat(
                label: 'Responses',
                value: '${task.responseCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(subtitle),
      ],
    );
  }
}

class _CustomerSearchPanel extends StatelessWidget {
  const _CustomerSearchPanel({required this.task});

  final TaskOpportunity task;

  @override
  Widget build(BuildContext context) {
    final notified = task.workersNotified;
    final responses = task.responsesReceived;
    final distributionStage = task.distributionStage.trim().isEmpty
        ? 'initial'
        : task.distributionStage.replaceAll('_', ' ');
    final searchMessage = switch (task.status) {
      'open' when task.isExpired => 'This task expired before a worker was confirmed.',
      'open' when responses == 0 && notified == 0 => 'Opportunity Radar is about to start looking for nearby workers.',
      'open' when responses == 0 => 'Still searching. Nearby workers are being alerted in waves.',
      'matched' => 'A worker has been selected. Search is complete.',
      'in_progress' => 'Your worker is on the move and the task is underway.',
      'completed' => 'This task is complete. Performance and payouts are now recorded.',
      _ => 'Task activity is updating in real time as workers view and respond.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(searchMessage),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SearchMetricChip(
                  icon: Icons.notifications_active_outlined,
                  label: 'Workers alerted',
                  value: '$notified',
                ),
                _SearchMetricChip(
                  icon: Icons.mark_chat_unread_outlined,
                  label: 'Responses received',
                  value: '$responses',
                ),
                _SearchMetricChip(
                  icon: Icons.radar_outlined,
                  label: 'Distribution stage',
                  value: _titleCase(distributionStage),
                ),
                _SearchMetricChip(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'Views',
                  value: '${task.viewCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMetricChip extends StatelessWidget {
  const _SearchMetricChip({
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
      constraints: const BoxConstraints(minWidth: 152),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

String _titleCase(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _WorkerLiveLocationPanel extends ConsumerStatefulWidget {
  const _WorkerLiveLocationPanel({
    required this.task,
    required this.currentUserId,
    required this.isOwner,
  });

  final TaskOpportunity task;
  final String currentUserId;
  final bool isOwner;

  @override
  ConsumerState<_WorkerLiveLocationPanel> createState() => _WorkerLiveLocationPanelState();
}

class _WorkerLiveLocationPanelState extends ConsumerState<_WorkerLiveLocationPanel> {
  StreamSubscription<AppLocation>? _locationSubscription;
  bool _isTracking = false;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isAssignedWorker = task.assignedWorkerId == widget.currentUserId;
    final canTrack = isAssignedWorker &&
        (task.status == 'matched' || task.status == 'in_progress');
    final liveLocationAsync = ref.watch(workerTaskLocationProvider(task.id));

    if (!canTrack && !widget.isOwner) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live worker location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            liveLocationAsync.when(
              data: (location) {
                if (location == null) {
                  return const MarketplaceStatusCard(
                    title: 'Tracking has not started',
                    message: 'No live location has been shared for this task yet.',
                    icon: Icons.location_searching_outlined,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(location.latitude, location.longitude),
                            zoom: 15,
                          ),
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: {
                            Marker(
                              markerId: MarkerId(location.taskId),
                              position: LatLng(location.latitude, location.longitude),
                              infoWindow: const InfoWindow(title: 'Worker location'),
                            ),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      location.addressText.trim().isEmpty
                          ? 'Updated ${taskRelativeTimeLabel(location.updatedAt)}'
                          : '${location.addressText} • ${taskRelativeTimeLabel(location.updatedAt)}',
                    ),
                  ],
                );
              },
              loading: () => const MarketplaceLoadingState(
                title: 'Loading live location',
                message: 'Checking whether the assigned worker is sharing their current position.',
              ),
              error: (error, _) => MarketplaceStatusCard(
                title: 'Location unavailable',
                message: 'Failed to load live location: $error',
                icon: Icons.location_off_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
            if (canTrack) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: _isTracking ? null : _startTracking,
                    child: const Text('Start live tracking'),
                  ),
                  OutlinedButton(
                    onPressed: _isTracking ? _stopTracking : null,
                    child: const Text('Stop tracking'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startTracking() async {
    setState(() {
      _isTracking = true;
    });

    final task = widget.task;
    final workerId = widget.currentUserId;

    await _locationSubscription?.cancel();
    _locationSubscription = ref.read(locationServiceProvider).liveLocationStream().listen((location) async {
      String? addressText = location.addressText;
      if ((addressText ?? '').trim().isEmpty) {
        addressText = await ref.read(locationServiceProvider).reverseGeocode(
              latitude: location.latitude,
              longitude: location.longitude,
            );
      }

      await ref.read(workerLocationRepositoryProvider).updateLocation(
            task: task,
            workerId: workerId,
            location: AppLocation(
              latitude: location.latitude,
              longitude: location.longitude,
              addressText: addressText,
            ),
          );
    });

    _locationSubscription!.onDone(() {
      if (mounted) {
        setState(() {
          _isTracking = false;
        });
      }
    });
  }

  Future<void> _stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await ref.read(workerLocationRepositoryProvider).clearLocation(widget.task.id);
    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
  }
}

class _TaskStatusActions extends ConsumerWidget {
  const _TaskStatusActions({
    required this.task,
    required this.currentUserId,
    required this.isOwner,
  });

  final TaskOpportunity task;
  final String currentUserId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAssignedWorker = task.assignedWorkerId == currentUserId;
    final canStart = task.status == 'matched' && (isOwner || isAssignedWorker);
    final canComplete = (task.status == 'matched' || task.status == 'in_progress') &&
        (isOwner || isAssignedWorker);
    final canRepost = isOwner && task.isExpired && task.assignedWorkerId == null;

    if (!canStart && !canComplete && !canRepost) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (canRepost)
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref.read(taskRepositoryProvider).repostTask(task: task);
                  if (context.mounted) {
                    showMarketplaceMessage(
                      context,
                      'Task reposted for another two-hour response window.',
                    );
                  }
                },
                icon: const Icon(Icons.restart_alt_outlined),
                label: const Text('Repost task'),
              ),
            if (canStart)
              FilledButton.tonal(
                onPressed: () async {
                  await ref.read(taskRepositoryProvider).markInProgress(
                        task: task,
                        actorId: currentUserId,
                      );
                  if (context.mounted) {
                    showMarketplaceMessage(context, 'Task started.');
                  }
                },
                child: const Text('Start task'),
              ),
            if (canComplete)
              FilledButton(
                onPressed: () async {
                  await ref.read(taskRepositoryProvider).markCompleted(
                        task: task,
                        actorId: currentUserId,
                      );
                  if (context.mounted) {
                    showMarketplaceMessage(
                      context,
                      'Task completed. Payment should be settled directly between customer and worker as agreed.',
                    );
                  }
                },
                child: const Text('Complete task'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletionPaymentNotice extends StatelessWidget {
  const _CompletionPaymentNotice();

  @override
  Widget build(BuildContext context) {
    return const MarketplaceStatusCard(
      title: 'Payment settlement',
      message: 'Payment should be settled directly between customer and worker as agreed.',
      icon: Icons.payments_outlined,
    );
  }
}

class _TrustedWorkerActionCard extends ConsumerWidget {
  const _TrustedWorkerActionCard({
    required this.ownerUserId,
    required this.task,
  });

  final String ownerUserId;
  final TaskOpportunity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerId = task.assignedWorkerId;
    if (workerId == null) {
      return const SizedBox.shrink();
    }

    final workerAsync = ref.watch(userProfileByIdProvider(workerId));
    final trustedAsync = ref.watch(
      isWorkerTrustedProvider((ownerUserId: ownerUserId, workerUserId: workerId)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trusted worker shortcut',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            workerAsync.when(
              data: (worker) {
                final workerName = worker?.displayName.trim().isNotEmpty == true
                    ? worker!.displayName
                    : workerId;

                return trustedAsync.when(
                  data: (isTrusted) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTrusted
                              ? '$workerName is already prioritized in your trusted network.'
                              : 'Save $workerName to prioritize them the next time you post a task.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () async {
                            if (isTrusted) {
                              await ref.read(workerNetworkRepositoryProvider).removeTrustedWorker(
                                    ownerUserId: ownerUserId,
                                    workerUserId: workerId,
                                  );
                            } else {
                              await ref.read(workerNetworkRepositoryProvider).trustWorker(
                                    ownerUserId: ownerUserId,
                                    workerUserId: workerId,
                                  );
                            }
                          },
                          child: Text(isTrusted ? 'Remove trusted status' : 'Save as trusted worker'),
                        ),
                      ],
                    );
                  },
                  loading: () => const MarketplaceLoadingState(
                    title: 'Loading trust state',
                    message: 'Checking whether this worker is already in your trusted network.',
                  ),
                  error: (error, _) => MarketplaceStatusCard(
                    title: 'Trust state unavailable',
                    message: 'Failed to load trust state: $error',
                    icon: Icons.verified_user_outlined,
                    tint: Theme.of(context).colorScheme.error,
                  ),
                );
              },
              loading: () => const MarketplaceLoadingState(
                title: 'Loading worker',
                message: 'Pulling the selected worker details into this task view.',
              ),
              error: (error, _) => MarketplaceStatusCard(
                title: 'Worker unavailable',
                message: 'Failed to load worker: $error',
                icon: Icons.person_search_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskChatPanel extends ConsumerWidget {
  const _TaskChatPanel({
    required this.task,
    required this.currentUserId,
  });

  final TaskOpportunity task;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerId = task.assignedWorkerId;
    if (workerId == null) {
      return const SizedBox.shrink();
    }

    final messagesAsync = ref.watch(
      taskMessagesProvider((
        taskId: task.id,
        customerId: task.createdBy,
        workerId: workerId,
      )),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task chat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const MarketplaceStatusCard(
                      title: 'No messages yet',
                      message: 'Start the conversation below to confirm timing, price, or arrival details.',
                      icon: Icons.chat_bubble_outline,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message,
                        isCurrentUser: message.senderId == currentUserId,
                      );
                    },
                  );
                },
                loading: () => const MarketplaceLoadingState(
                  title: 'Loading chat',
                  message: 'Syncing the latest messages and offer updates for this task.',
                ),
                error: (error, _) => MarketplaceStatusCard(
                  title: 'Chat unavailable',
                  message: 'Failed to load chat: $error',
                  icon: Icons.chat_bubble_outline,
                  tint: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TaskMessageComposer(task: task, currentUserId: currentUserId),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  final TaskMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = message.isSystem
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : isCurrentUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerLow;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isOffer && message.offerAmount != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskCurrencyLabel(
                          message.offerCurrency ?? 'ZAR',
                          message.offerAmount!,
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(message.text),
              const SizedBox(height: 6),
              Text(
                taskRelativeTimeLabel(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskMessageComposer extends ConsumerStatefulWidget {
  const _TaskMessageComposer({
    required this.task,
    required this.currentUserId,
  });

  final TaskOpportunity task;
  final String currentUserId;

  @override
  ConsumerState<_TaskMessageComposer> createState() => _TaskMessageComposerState();
}

class _TaskMessageComposerState extends ConsumerState<_TaskMessageComposer> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isSending,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Confirm details or coordinate arrival',
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isSending ? null : _send,
              child: Text(_isSending ? 'Sending...' : 'Send'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSending ? null : _sendOffer,
          icon: const Icon(Icons.local_offer_outlined),
          label: const Text('Send offer'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(messageRepositoryProvider).sendTextMessage(
            task: widget.task,
            senderId: widget.currentUserId,
            text: text,
          );

      if (!mounted) {
        return;
      }

      _controller.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendOffer() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _OfferDialog(task: widget.task),
    );

    if (amount == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(messageRepositoryProvider).sendOfferMessage(
            task: widget.task,
            senderId: widget.currentUserId,
            amount: amount,
            note: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
          );

      if (!mounted) {
        return;
      }

      _controller.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}

class _OfferDialog extends StatefulWidget {
  const _OfferDialog({required this.task});

  final TaskOpportunity task;

  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.task.budgetAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send an offer'),
      content: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Offer amount (${widget.task.currency})',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount == null || amount <= 0) {
              return;
            }
            Navigator.of(context).pop(amount);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _TaskRatingPanel extends ConsumerWidget {
  const _TaskRatingPanel({
    required this.task,
    required this.currentUserId,
    required this.isOwner,
  });

  final TaskOpportunity task;
  final String currentUserId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartId = isOwner ? task.assignedWorkerId : task.createdBy;
    if (counterpartId == null || counterpartId == currentUserId) {
      return const SizedBox.shrink();
    }

    final ratingAsync = ref.watch(
      userTaskRatingProvider((taskId: task.id, fromUserId: currentUserId)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ratingAsync.when(
          data: (rating) {
            if (rating != null) {
              return _ExistingRatingView(rating: rating, isOwner: isOwner);
            }

            return _TaskRatingComposer(
              task: task,
              currentUserId: currentUserId,
              counterpartId: counterpartId,
              isOwner: isOwner,
            );
          },
          loading: () => const MarketplaceLoadingState(
            title: 'Loading rating state',
            message: 'Checking whether a review has already been submitted for this task.',
          ),
          error: (error, _) => MarketplaceStatusCard(
            title: 'Rating unavailable',
            message: 'Failed to load rating state: $error',
            icon: Icons.star_outline,
            tint: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _ExistingRatingView extends StatelessWidget {
  const _ExistingRatingView({required this.rating, required this.isOwner});

  final TaskRating rating;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final targetLabel = isOwner ? 'worker' : 'customer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your rating for the $targetLabel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text('Average: ${rating.averageScore.toStringAsFixed(1)} / 5'),
        const SizedBox(height: 4),
        Text('Reliability: ${rating.reliability}'),
        Text('Communication: ${rating.communication}'),
        Text('Speed: ${rating.speed}'),
        Text('Professionalism: ${rating.professionalism}'),
        if (rating.comment.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(rating.comment),
        ],
      ],
    );
  }
}

class _TaskRatingComposer extends ConsumerStatefulWidget {
  const _TaskRatingComposer({
    required this.task,
    required this.currentUserId,
    required this.counterpartId,
    required this.isOwner,
  });

  final TaskOpportunity task;
  final String currentUserId;
  final String counterpartId;
  final bool isOwner;

  @override
  ConsumerState<_TaskRatingComposer> createState() => _TaskRatingComposerState();
}

class _TaskRatingComposerState extends ConsumerState<_TaskRatingComposer> {
  final _commentController = TextEditingController();
  int _reliability = 5;
  int _communication = 5;
  int _speed = 5;
  int _professionalism = 5;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = widget.isOwner ? 'worker' : 'customer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate the $targetLabel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        const Text('This review updates the counterpart profile trust metrics.'),
        const SizedBox(height: 16),
        _RatingField(
          label: 'Reliability',
          value: _reliability,
          onChanged: (value) => setState(() => _reliability = value),
        ),
        _RatingField(
          label: 'Communication',
          value: _communication,
          onChanged: (value) => setState(() => _communication = value),
        ),
        _RatingField(
          label: 'Speed',
          value: _speed,
          onChanged: (value) => setState(() => _speed = value),
        ),
        _RatingField(
          label: 'Professionalism',
          value: _professionalism,
          onChanged: (value) => setState(() => _professionalism = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          enabled: !_isSubmitting,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText: 'Optional review comment',
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Submitting...' : 'Submit rating'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(ratingRepositoryProvider).submitRating(
            task: widget.task,
            fromUserId: widget.currentUserId,
            reliability: _reliability,
            communication: _communication,
            speed: _speed,
            professionalism: _professionalism,
            comment: _commentController.text,
          );

      ref.invalidate(userTaskRatingProvider((
        taskId: widget.task.id,
        fromUserId: widget.currentUserId,
      )));

      if (!mounted) {
        return;
      }

      showMarketplaceMessage(context, 'Rating submitted.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _RatingField extends StatelessWidget {
  const _RatingField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 - Poor')),
          DropdownMenuItem(value: 2, child: Text('2 - Fair')),
          DropdownMenuItem(value: 3, child: Text('3 - Good')),
          DropdownMenuItem(value: 4, child: Text('4 - Very good')),
          DropdownMenuItem(value: 5, child: Text('5 - Excellent')),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _WorkerResponseComposer extends ConsumerStatefulWidget {
  const _WorkerResponseComposer({required this.task, required this.workerId});

  final TaskOpportunity task;
  final String workerId;

  @override
  ConsumerState<_WorkerResponseComposer> createState() =>
      _WorkerResponseComposerState();
}

class _WorkerResponseComposerState extends ConsumerState<_WorkerResponseComposer> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _offerController = TextEditingController();
  final _etaController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _offerController.text = widget.task.budgetAmount.toStringAsFixed(0);
    _etaController.text = '10';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _offerController.dispose();
    _etaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Respond to this task',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Message to customer'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a short response message.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _offerController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Your offer (ZAR)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid offer amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _etaController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'ETA in minutes'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final eta = int.tryParse((value ?? '').trim());
                  if (eta == null || eta <= 0) {
                    return 'Enter a valid arrival estimate.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Sending...' : 'Send response'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(taskResponseRepositoryProvider).submitResponse(
            task: widget.task,
            workerId: widget.workerId,
            message: _messageController.text,
            offeredAmount: double.parse(_offerController.text.trim()),
            estimatedArrivalMinutes: int.parse(_etaController.text.trim()),
          );

      if (!mounted) {
        return;
      }

      showMarketplaceMessage(context, 'Response sent.');
      _messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _ResponseCard extends ConsumerWidget {
  const _ResponseCard({
    required this.task,
    required this.response,
    required this.isOwner,
    required this.currentUserId,
  });

  final TaskOpportunity task;
  final TaskResponse response;
  final bool isOwner;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectedWorker = currentUserId != null && response.workerId == currentUserId;
    final canAccept = isOwner && task.assignedWorkerId == null && task.isOpen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(response.status.toUpperCase())),
                if (isSelectedWorker) ...[
                  const SizedBox(width: 8),
                  const Chip(label: Text('Your response')),
                ],
                const Spacer(),
                Text(taskCurrencyLabel(task.currency, response.offeredAmount)),
              ],
            ),
            const SizedBox(height: 12),
            Text(response.message),
            const SizedBox(height: 8),
            Text('Arrival estimate: ${response.estimatedArrivalMinutes} minutes'),
            const SizedBox(height: 4),
            Text(taskRelativeTimeLabel(response.createdAt)),
            if (canAccept) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref.read(taskResponseRepositoryProvider).acceptResponse(
                        task: task,
                        acceptedResponse: response,
                      );
                  if (context.mounted) {
                    showMarketplaceMessage(context, 'Worker chosen for this task.');
                  }
                },
                child: const Text('Choose worker'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
