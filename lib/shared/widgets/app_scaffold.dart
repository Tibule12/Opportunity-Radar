import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    super.key,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ['/feed', '/map', '/post-task', '/dashboard', '/profile'];
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final location = GoRouterState.of(context).uri.toString();
    final appBarActions = <Widget>[
      if (!location.startsWith('/notifications'))
        IconButton(
          onPressed: () => context.go('/notifications'),
          tooltip: 'Notifications',
          icon: unreadCount > 0
              ? Badge.count(
                  count: unreadCount,
                  child: const Icon(Icons.notifications_none_outlined),
                )
              : const Icon(Icons.notifications_none_outlined),
        ),
      ...?actions,
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -140,
            left: -60,
            child: _GlowOrb(
              size: 260,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: _GlowOrb(
              size: 220,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
            ),
          ),
          SafeArea(
            child: child,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) {
          final destination = destinations[index];
          if (GoRouterState.of(context).matchedLocation != destination) {
            context.go(destination);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/map')) {
      return 1;
    }
    if (location.startsWith('/post-task')) {
      return 2;
    }
    if (location.startsWith('/dashboard')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
