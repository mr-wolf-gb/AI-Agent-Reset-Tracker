import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/lock_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/accounts/account_list_screen.dart';
import '../screens/accounts/add_edit_account_screen.dart';
import '../screens/ai_ides/ai_ide_list_screen.dart';
import '../screens/ai_ides/add_custom_ide_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final settings = ref.watch(settingsProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash' || loc == '/lock') return null;
      if (settings.biometricEnabled && auth == AuthStatus.unauthenticated) {
        return '/lock';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (_, __) => const LockScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/ide/:ideId',
            builder: (_, state) => AccountListScreen(
              ideId: state.pathParameters['ideId']!,
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, state) => AddEditAccountScreen(
                  ideId: state.pathParameters['ideId']!,
                ),
              ),
              GoRoute(
                path: 'edit/:accountId',
                builder: (_, state) => AddEditAccountScreen(
                  ideId: state.pathParameters['ideId']!,
                  accountId: state.pathParameters['accountId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/ides',
            builder: (_, __) => const AiIdeListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddCustomIdeScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
