import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/task_opportunity.dart';
import '../../../shared/utils/distance_utils.dart';
import '../../../shared/utils/opportunity_visibility.dart';
import '../../../shared/utils/task_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/state_panels.dart';
import '../../../shared/widgets/task_expiry_badge.dart';

class OpportunityMapScreen extends ConsumerStatefulWidget {
  const OpportunityMapScreen({super.key});

  @override
  ConsumerState<OpportunityMapScreen> createState() => _OpportunityMapScreenState();
}

class _OpportunityMapScreenState extends ConsumerState<OpportunityMapScreen> {
  String _selectedCategory = 'all';
  double _maxDistanceKm = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final tasksAsync = ref.watch(openTasksProvider);

    return AppScaffold(
      title: 'Opportunity Map',
      child: tasksAsync.when(
        data: (tasks) {
          final baseTasks = visibleTasksForProfile(
            tasks: tasks,
            currentProfile: profile,
            currentUserId: currentUserId,
          ).where((task) => task.hasCoordinates).toList();

          final visibleTasks = _filteredTasks(baseTasks, profile);

          if (visibleTasks.isEmpty) {
            return MarketplaceStatusCard(
              title: baseTasks.isEmpty ? 'Nothing to map yet' : 'No tasks match these filters',
              message: baseTasks.isEmpty
                  ? 'No mappable tasks are available yet. Add coordinates to tasks or your profile to use the map.'
                  : 'Expand the radius or switch categories to bring more live tasks back onto the map.',
              icon: baseTasks.isEmpty ? Icons.map_outlined : Icons.filter_alt_off_outlined,
            );
          }

          final initialTask = visibleTasks.first;
          final initialTarget = profile != null && profile.hasLocation
              ? LatLng(profile.locationLat!, profile.locationLng!)
              : LatLng(initialTask.locationLat!, initialTask.locationLng!);

          final markers = {
            for (final task in visibleTasks)
              Marker(
                markerId: MarkerId(task.id),
                position: LatLng(task.locationLat!, task.locationLng!),
                infoWindow: InfoWindow(
                  title: task.title,
                  snippet: task.locationAddress,
                  onTap: () => context.go('/tasks/${task.id}'),
                ),
              ),
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MapHeroCard(
                      visibleTaskCount: visibleTasks.length,
                      category: _selectedCategory,
                      radiusKm: _maxDistanceKm,
                      locationLabel: profile?.locationAddress,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Map filters',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 42,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final category in const [
                                    'all',
                                    'delivery',
                                    'transport',
                                    'errands',
                                    'moving_help',
                                    'other',
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(category == 'all' ? 'All' : _categoryLabel(category)),
                                        selected: _selectedCategory == category,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedCategory = category;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Radius: ${_maxDistanceKm.toStringAsFixed(0)} km'),
                                Expanded(
                                  child: Slider(
                                    value: _maxDistanceKm,
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                                    onChanged: profile != null && profile.hasLocation
                                        ? (value) {
                                            setState(() {
                                              _maxDistanceKm = value;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialTarget,
                        zoom: profile != null && profile.hasLocation ? 12 : 11,
                      ),
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: markers,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 178,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      final distanceKm = distanceFromProfile(profile, task);
                      return _MapTaskCard(
                        task: task,
                        distanceKm: distanceKm,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const MarketplaceLoadingState(
          title: 'Loading the map',
          message: 'Syncing nearby tasks and positioning the live opportunity view.',
        ),
        error: (error, _) => MarketplaceStatusCard(
          title: 'Map unavailable',
          message: 'Failed to load map data: $error',
          icon: Icons.map_outlined,
          tint: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  List<TaskOpportunity> _filteredTasks(List<TaskOpportunity> tasks, dynamic profile) {
    return tasks.where((task) {
      if (_selectedCategory != 'all' && task.category != _selectedCategory) {
        return false;
      }

      final distanceKm = distanceFromProfile(profile, task);
      if (distanceKm != null && distanceKm > _maxDistanceKm) {
        return false;
      }

      return true;
    }).toList();
  }
}

class _MapHeroCard extends StatelessWidget {
  const _MapHeroCard({
    required this.visibleTaskCount,
    required this.category,
    required this.radiusKm,
    required this.locationLabel,
  });

  final int visibleTaskCount;
  final String category;
  final double radiusKm;
  final String? locationLabel;

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
            'Opportunity map',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$visibleTaskCount mappable opportunities in ${category == 'all' ? 'all categories' : _categoryLabel(category).toLowerCase()} within ${radiusKm.toStringAsFixed(0)} km.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          if ((locationLabel ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Anchored around $locationLabel',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapTaskCard extends StatelessWidget {
  const _MapTaskCard({
    required this.task,
    required this.distanceKm,
  });

  final TaskOpportunity task;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(label: Text(taskCategoryLabel(task.category))),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.locationAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(taskCurrencyLabel(task.currency, task.budgetAmount)),
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(distanceLabelKm(distanceKm!)),
              ],
              const SizedBox(height: 8),
              TaskExpiryBadge(expiresAt: task.expiresAt),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => context.go('/tasks/${task.id}'),
                child: const Text('View task'),
              ),
            ],
          ),
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
