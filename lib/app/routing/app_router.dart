import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/earnings/presentation/earnings_screen.dart';
import '../../features/feed/presentation/opportunity_feed_screen.dart';
import '../../features/map/presentation/opportunity_map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/data/user_profile_repository.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/post_task_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static final _auth = FirebaseAuth.instance;
  static final _profiles = UserProfileRepository(FirebaseFirestore.instance);

  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(_auth.authStateChanges()),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return location == '/' ? null : '/';
      }

      final profile = await _profiles.fetchUserProfile(currentUser.uid);
      final needsProfile = profile == null || !profile.isComplete;

      if (needsProfile) {
        return location == '/complete-profile' ? null : '/complete-profile';
      }

      if (location == '/' || location == '/complete-profile') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const OpportunityFeedScreen(),
      ),
      GoRoute(
        path: '/post-task',
        builder: (context, state) => const PostTaskScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const OpportunityMapScreen(),
      ),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['taskId']!,
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
