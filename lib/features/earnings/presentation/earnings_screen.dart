import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/earnings_record.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final earningsAsync = ref.watch(workerEarningsRecordsProvider);

    return AppScaffold(
      title: 'Earnings',
      child: profileAsync.when(
        data: (profile) {
          if (profile == null || !profile.roles.contains('worker')) {
            return const MarketplaceStatusCard(
              title: 'Worker earnings only',
              message: 'Estimated earnings records are available for worker accounts after completed tasks.',
              icon: Icons.payments_outlined,
            );
          }

          return earningsAsync.when(
            data: (records) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF13231F), Color(0xFF0E7A6D)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated earnings',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'These values are informational only for MVP. Payment should be settled directly between customer and worker as agreed.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 760 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth > 760 ? 1.35 : 1.2,
                        children: [
                          _MetricTile(label: 'Today', value: taskCurrencyLabel('ZAR', profile.earningsToday)),
                          _MetricTile(label: 'This week', value: taskCurrencyLabel('ZAR', profile.earningsWeek)),
                          _MetricTile(label: 'This month', value: taskCurrencyLabel('ZAR', profile.earningsMonth)),
                          _MetricTile(label: 'Lifetime', value: taskCurrencyLabel('ZAR', profile.earningsLifetime)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  if (records.isEmpty)
                    const MarketplaceStatusCard(
                      title: 'No earnings records yet',
                      message: 'Complete a worker task and the agreed amount will appear here for tracking.',
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    ...[
                      for (var index = 0; index < records.length; index++) ...[
                        _EarningsRecordCard(record: records[index]),
                        if (index < records.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                ],
              );
            },
            loading: () => const MarketplaceLoadingState(
              title: 'Loading earnings',
              message: 'Pulling your estimated work value and completed task ledger.',
            ),
            error: (error, _) => MarketplaceStatusCard(
              title: 'Earnings unavailable',
              message: 'Failed to load earnings records: $error',
              icon: Icons.payments_outlined,
              tint: Theme.of(context).colorScheme.error,
            ),
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading earnings',
          message: 'Checking worker profile access for estimated earnings.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Earnings unavailable',
          message: 'Failed to load worker profile: $error',
          icon: Icons.payments_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsRecordCard extends StatelessWidget {
  const _EarningsRecordCard({required this.record});

  final EarningsRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.taskTitle == null || '${record.taskTitle}'.trim().isEmpty
                        ? 'Task ${record.taskId}'
                        : record.taskTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.completedAt == null
                        ? 'Completed recently'
                        : taskRelativeTimeLabel(record.completedAt).replaceFirst('Posted ', 'Completed '),
                  ),
                  const SizedBox(height: 4),
                  const Text('Payment settled externally between customer and worker'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              taskCurrencyLabel(record.currency, record.agreedAmount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}