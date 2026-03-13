import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class OpportunityRadarApp extends ConsumerWidget {
  const OpportunityRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseReady = ref.watch(firebaseReadyProvider);

    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Opportunity Radar',
        theme: AppTheme.light(),
        home: const _FirebaseSetupRequiredScreen(),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Opportunity Radar',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const _AppBootstrapper(),
          ],
        );
      },
    );
  }
}

class _AppBootstrapper extends ConsumerStatefulWidget {
  const _AppBootstrapper();

  @override
  ConsumerState<_AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<_AppBootstrapper> {
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) {
        ref.read(pushNotificationServiceProvider).syncForUser(next.valueOrNull?.uid);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _FirebaseSetupRequiredScreen extends StatelessWidget {
  const _FirebaseSetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase setup is required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The app code is in place, but Firebase could not be initialized in this environment. Run flutter create ., configure FlutterFire, and add the platform Firebase files before launching the mobile app.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
