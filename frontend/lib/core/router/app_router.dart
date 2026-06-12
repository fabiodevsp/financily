import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/transactions/presentation/screens/summary_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/upload/presentation/screens/upload_screen.dart';

/// Notifica o GoRouter para reavaliar `redirect` sempre que
/// [authControllerProvider] mudar de estado (login, logout, sessão
/// expirada). Não usa `@riverpod` codegen — ver "Decisões arquiteturais"
/// da Fase 4 em docs/project_status.md.
class GoRouterRefreshListenable extends ChangeNotifier {
  GoRouterRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final goRouterRefreshProvider = Provider<GoRouterRefreshListenable>((ref) {
  return GoRouterRefreshListenable(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: ref.watch(goRouterRefreshProvider),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/upload', builder: (_, __) => const UploadScreen()),
      GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
      GoRoute(path: '/summary', builder: (_, __) => const SummaryScreen()),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isAuthRoute = location == '/login' || location == '/register';

      switch (authState.status) {
        case AuthStatus.unknown:
          return isSplash ? null : '/splash';
        case AuthStatus.authenticating:
          return null;
        case AuthStatus.authenticated:
          return (isSplash || isAuthRoute) ? '/dashboard' : null;
        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : '/login';
      }
    },
  );
});
