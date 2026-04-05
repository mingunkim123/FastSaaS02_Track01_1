import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/shared/providers/auth_provider.dart';
import 'package:flutter_app/shared/widgets/bottom_nav_shell.dart';
import 'package:flutter_app/features/calendar/calendar_page.dart';
import 'package:flutter_app/features/ai_chat/ai_chat_page.dart';

// Placeholder screen widgets - will be replaced with actual pages
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: const Center(child: Text('Login Page')),
    );
  }
}

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: const Center(child: Text('Record Page')),
    );
  }
}


class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: const Center(child: Text('Stats Page')),
    );
  }
}


/// Go Router configuration
/// Defines all routes and navigation logic for the app
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the auth state to trigger redirects
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/record',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Check if the auth state is loading
      if (authState.isLoading) {
        return null;
      }

      // Check authentication state
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      // If not authenticated and not already on login page, redirect to login
      if (!isAuthenticated && state.matchedLocation != '/login') {
        return '/login';
      }

      // If authenticated and on login page, redirect to record page
      if (isAuthenticated && state.matchedLocation == '/login') {
        return '/record';
      }

      return null;
    },
    routes: [
      // Login route (no shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Shell route for authenticated pages with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavShell(child: child);
        },
        routes: [
          // Record route
          GoRoute(
            path: '/record',
            name: 'record',
            builder: (context, state) => const RecordPage(),
          ),

          // Calendar route
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarPage(),
          ),

          // Stats route
          GoRoute(
            path: '/stats',
            name: 'stats',
            builder: (context, state) => const StatsPage(),
          ),

          // AI Chat route
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (context, state) => const AIChatPage(),
          ),
        ],
      ),
    ],
    // Error handling for unknown routes
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('페이지를 찾을 수 없습니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/record'),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
