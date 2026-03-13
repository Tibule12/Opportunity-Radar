import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/worker_network_entry.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

    return AppScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) {
              context.go('/');
            }
          },
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
        ),
      ],
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return MarketplaceStatusCard(
              title: 'Finish your profile',
              message: 'This account does not have a saved profile yet.',
              icon: Icons.person_outline,
              actionLabel: 'Complete profile',
              onAction: () => context.go('/complete-profile'),
            );
          }

          return _ProfileContent(
            profile: profile,
            currentUserId: currentUser?.uid,
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading profile',
          message: 'Bringing in identity, trust signals, and saved worker relationships.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Profile unavailable',
          message: 'Failed to load profile: $error',
          icon: Icons.person_off_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.currentUserId,
  });

  final UserProfile profile;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final roleLabel = profile.roles.map(_labelForRole).join(' and ');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProfileHeroCard(
          profile: profile,
          roleLabel: roleLabel,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProfileMetricCard(
                label: 'Rating',
                value: profile.ratingAverage.toStringAsFixed(1),
                footnote: '${profile.ratingCount} ratings',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileMetricCard(
                label: 'Completed',
                value: '${profile.completedTaskCount}',
                footnote: 'jobs closed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (currentUserId != null && profile.roles.contains('worker'))
          _AvailabilityToggle(
            currentUserId: currentUserId!,
            availabilityStatus: profile.availabilityStatus,
          ),
        _ProfileTile(
          title: 'Phone number',
          subtitle: profile.phoneNumber.isEmpty ? 'Not available' : profile.phoneNumber,
        ),
        _ProfileTile(
          title: 'Referral code',
          subtitle: profile.referralCode.isEmpty ? 'Generating your code...' : profile.referralCode,
        ),
        _ProfileTile(
          title: 'Rating',
          subtitle:
              '${profile.ratingAverage.toStringAsFixed(1)} average across ${profile.completedTaskCount} completed tasks',
        ),
        _ProfileTile(
          title: 'Availability',
          subtitle: _labelForAvailability(profile.availabilityStatus),
        ),
        _ProfileTile(
          title: 'Base location',
          subtitle: profile.locationAddress.isEmpty
              ? 'No base location saved'
              : profile.locationAddress,
        ),
        _ProfileTile(
          title: 'Trust badges',
          subtitle: profile.trustBadges.isEmpty
              ? 'No badges yet'
              : profile.trustBadges.join(', '),
        ),
        _ProfileTile(
          title: 'Push notifications',
          subtitle: profile.deviceTokens.isEmpty
              ? 'This device has not registered a push token yet.'
              : '${profile.deviceTokens.length} active device token${profile.deviceTokens.length == 1 ? '' : 's'}',
        ),
        _ProfileTile(
          title: 'Referral rewards',
          subtitle: '${profile.rewardPoints} reward point${profile.rewardPoints == 1 ? '' : 's'} earned',
        ),
        if (currentUserId != null && profile.roles.contains('worker'))
          _ProfileActionTile(
            title: 'Estimated earnings ledger',
            subtitle: 'Open your full informational earnings history.',
            icon: Icons.payments_outlined,
            onTap: () => context.go('/earnings'),
          ),
        if (currentUserId != null && profile.roles.contains('worker'))
          const _ReferralNetworkSection(),
        if (currentUserId != null)
          _TrustedWorkersSection(ownerUserId: currentUserId!),
      ],
    );
  }
}

class _ReferralNetworkSection extends ConsumerWidget {
  const _ReferralNetworkSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referredWorkersAsync = ref.watch(referredWorkersProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referral network',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            referredWorkersAsync.when(
              data: (workers) {
                if (workers.isEmpty) {
                  return const MarketplaceStatusCard(
                    title: 'No referred workers yet',
                    message: 'When someone signs up with your code, their progress will appear here.',
                    icon: Icons.group_outlined,
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < workers.length; index++) ...[
                      _ReferralWorkerTile(worker: workers[index]),
                      if (index < workers.length - 1) const Divider(height: 20),
                    ],
                  ],
                );
              },
              loading: () => const MarketplaceLoadingState(
                title: 'Loading referral network',
                message: 'Fetching workers who joined through your invite code.',
              ),
              error: (error, _) => MarketplaceStatusCard(
                title: 'Referral network unavailable',
                message: 'Failed to load referred workers: $error',
                icon: Icons.group_off_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralWorkerTile extends StatelessWidget {
  const _ReferralWorkerTile({required this.worker});

  final UserProfile worker;

  @override
  Widget build(BuildContext context) {
    final title = worker.displayName.trim().isEmpty ? worker.phoneNumber : worker.displayName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(worker.initials)),
      title: Text(title),
      subtitle: Text(
        '${_labelForAvailability(worker.availabilityStatus)} • ${worker.completedTaskCount} completed • ${worker.ratingAverage.toStringAsFixed(1)} rating',
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.roleLabel,
  });

  final UserProfile profile;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13231F), Color(0xFF28536B)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_labelForVerification(profile.verificationStatus)} $roleLabel',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileHeroTag(label: _labelForAvailability(profile.availabilityStatus)),
                    _ProfileHeroTag(
                      label: profile.locationAddress.isEmpty ? 'Location not set' : profile.locationAddress,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroTag extends StatelessWidget {
  const _ProfileHeroTag({required this.label});

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

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.label,
    required this.value,
    required this.footnote,
  });

  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(footnote),
          ],
        ),
      ),
    );
  }
}

class _TrustedWorkersSection extends ConsumerWidget {
  const _TrustedWorkersSection({required this.ownerUserId});

  final String ownerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustedWorkersAsync = ref.watch(trustedWorkersProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trusted workers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            trustedWorkersAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const MarketplaceStatusCard(
                    title: 'No trusted workers yet',
                    message: 'Save a great worker from task detail and they will show up here for faster repeat hiring.',
                    icon: Icons.group_add_outlined,
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < entries.length; index++) ...[
                      _TrustedWorkerTile(
                        ownerUserId: ownerUserId,
                        entry: entries[index],
                      ),
                      if (index < entries.length - 1) const Divider(height: 20),
                    ],
                  ],
                );
              },
              loading: () => const MarketplaceLoadingState(
                title: 'Loading trusted workers',
                message: 'Fetching the workers you have saved for repeat tasks.',
              ),
              error: (error, _) => MarketplaceStatusCard(
                title: 'Trusted workers unavailable',
                message: 'Failed to load trusted workers: $error',
                icon: Icons.group_off_outlined,
                tint: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustedWorkerTile extends ConsumerWidget {
  const _TrustedWorkerTile({
    required this.ownerUserId,
    required this.entry,
  });

  final String ownerUserId;
  final WorkerNetworkEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileByIdProvider(entry.workerUserId));

    return profileAsync.when(
      data: (profile) {
        final title = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName
            : entry.workerUserId;
        final subtitle = profile == null
            ? 'Trusted worker'
            : '${_labelForAvailability(profile.availabilityStatus)} • ${profile.ratingAverage.toStringAsFixed(1)} rating';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: IconButton(
            onPressed: () async {
              await ref.read(workerNetworkRepositoryProvider).removeTrustedWorker(
                    ownerUserId: ownerUserId,
                    workerUserId: entry.workerUserId,
                  );
            },
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'Remove trusted worker',
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: MarketplaceLoadingState(
          title: 'Loading worker',
          message: 'Pulling in profile details for this trusted contact.',
        ),
      ),
      error: (error, _) => MarketplaceStatusCard(
        title: 'Worker unavailable',
        message: 'Failed to load worker profile: $error',
        icon: Icons.person_search_outlined,
        tint: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _AvailabilityToggle extends ConsumerWidget {
  const _AvailabilityToggle({
    required this.currentUserId,
    required this.availabilityStatus,
  });

  final String currentUserId;
  final String availabilityStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(_labelForAvailability(availabilityStatus)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: availabilityStatus,
              items: const [
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'busy', child: Text('Busy')),
                DropdownMenuItem(value: 'offline', child: Text('Offline')),
              ],
              onChanged: (value) async {
                if (value == null || value == availabilityStatus) {
                  return;
                }

                await ref.read(userProfileRepositoryProvider).updateAvailability(
                      uid: currentUserId,
                      availabilityStatus: value,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _labelForRole(String role) {
  switch (role) {
    case 'customer':
      return 'customer';
    case 'worker':
      return 'worker';
    default:
      return role;
  }
}

String _labelForVerification(String status) {
  if (status == 'verified') {
    return 'Verified';
  }

  return 'Unverified';
}

String _labelForAvailability(String status) {
  switch (status) {
    case 'online':
      return 'Online';
    case 'busy':
      return 'Busy on task';
    default:
      return 'Offline';
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_outlined),
        onTap: onTap,
      ),
    );
  }
}
