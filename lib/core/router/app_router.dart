import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowtop/core/constants/app_constants.dart';
import 'package:flowtop/features/auth/presentation/pages/auth_page.dart';
import 'package:flowtop/features/auth/presentation/pages/onboarding_page.dart';
import 'package:flowtop/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flowtop/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flowtop/features/auth/presentation/pages/sign_up_page.dart';
import 'package:flowtop/features/auth/presentation/pages/splash_page.dart';
import 'package:flowtop/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flowtop/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flowtop/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flowtop/features/projects/presentation/pages/project_create_page.dart';
import 'package:flowtop/features/projects/presentation/pages/project_detail_page.dart';
import 'package:flowtop/features/projects/presentation/pages/project_list_page.dart';
import 'package:flowtop/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:flowtop/features/profile/presentation/pages/profile_page.dart';
import 'package:flowtop/features/statistics/presentation/pages/statistics_page.dart';
import 'package:flowtop/features/tasks/presentation/pages/task_create_page.dart';
import 'package:flowtop/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:flowtop/features/tasks/presentation/pages/task_edit_page.dart';
import 'package:flowtop/features/tasks/presentation/pages/task_list_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_create_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_detail_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_invitations_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_list_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/workspace_members_page.dart';
import 'package:flowtop/features/workspaces/presentation/pages/my_invitations_page.dart';

/// Application router using GoRouter.
///
/// Redirect decisions are made synchronously from the Firebase Auth session so
/// the router reacts to sign-in / sign-out without circular Riverpod
/// dependencies. The router listens to auth changes and re-evaluates the
/// current location whenever the session starts or ends (for example when a
/// token is revoked), so users are never left on a screen that needs a session.
class AppRouter {
  AppRouter._();

  static final _AuthRefreshNotifier _authRefresh =
      _AuthRefreshNotifier(FirebaseAuth.instance.authStateChanges());

  static final GoRouter router = createAppRouter(
    isSignedIn: () => FirebaseAuth.instance.currentUser != null,
    refreshListenable: _authRefresh,
  );
}

/// Notifies the router whenever the Firebase Auth session changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<User?> authChanges) {
    _subscription = authChanges.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// The path of [route] relative to its [parent] route.
///
/// Sub-routes must be declared with relative paths, but [AppRoutes] holds the
/// full paths so the URLs stay defined in one place.
String _subPath(String parent, String route) {
  assert(route.startsWith('$parent/'), '$route must live under $parent');
  return route.substring(parent.length + 1);
}

/// Builds the application router.
///
/// [isSignedIn] is evaluated on every navigation. Provide a [refreshListenable]
/// that notifies when its answer can change so the current location is checked
/// again. Tests inject both to exercise the real route tree without Firebase.
GoRouter createAppRouter({
  required bool Function() isSignedIn,
  Listenable? refreshListenable,
  String initialLocation = AppRoutes.splash,
}) {
  const authPages = <String>{
    AppRoutes.auth,
    AppRoutes.signIn,
    AppRoutes.signUp,
    AppRoutes.resetPassword,
  };

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final signedIn = isSignedIn();
      final location = state.matchedLocation;
      final isAuthPage = authPages.contains(location);
      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;

      // Signed out: send to sign-in (unless already on an auth page or splash).
      if (!signedIn && !isAuthPage && !isSplash && !isOnboarding) {
        return AppRoutes.signIn;
      }
      // Signed in: leave onboarding/auth pages behind, go to dashboard.
      if (signedIn && (isAuthPage || isOnboarding)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Auth
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      // Shell with bottom navigation for authenticated features. The order of
      // the branches must match [ScaffoldWithNavBar.destinations].
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: _subPath(AppRoutes.dashboard, AppRoutes.notifications),
                    name: 'notifications',
                    builder: (context, state) => const NotificationsPage(),
                  ),
                  GoRoute(
                    path: _subPath(AppRoutes.dashboard, AppRoutes.statistics),
                    name: 'statistics',
                    builder: (context, state) => const StatisticsPage(),
                  ),
                ],
              ),
            ],
          ),
          // Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.taskList,
                name: 'taskList',
                builder: (context, state) => const TaskListPage(),
                routes: [
                  GoRoute(
                    path: _subPath(AppRoutes.taskList, AppRoutes.taskCreate),
                    name: 'taskCreate',
                    builder: (context, state) => const TaskCreatePage(),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.taskList, AppRoutes.taskDetail)}/:taskId',
                    name: 'taskDetail',
                    builder: (context, state) => TaskDetailPage(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.taskList, AppRoutes.taskEdit)}/:taskId',
                    name: 'taskEdit',
                    builder: (context, state) => TaskEditPage(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Projects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.projects,
                name: 'projects',
                builder: (context, state) => const ProjectListPage(),
                routes: [
                  GoRoute(
                    path: _subPath(AppRoutes.projects, AppRoutes.projectCreate),
                    name: 'projectCreate',
                    builder: (context, state) => const ProjectCreatePage(),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.projects, AppRoutes.projectDetail)}/:projectId',
                    name: 'projectDetail',
                    builder: (context, state) => ProjectDetailPage(
                      projectId: state.pathParameters['projectId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          // Spaces
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workspaces,
                name: 'workspaces',
                builder: (context, state) => const WorkspaceListPage(),
                routes: [
                  GoRoute(
                    path: _subPath(
                        AppRoutes.workspaces, AppRoutes.workspaceCreate),
                    name: 'workspaceCreate',
                    builder: (context, state) => const WorkspaceCreatePage(),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.workspaces, AppRoutes.workspaceDetail)}/:workspaceId',
                    name: 'workspaceDetail',
                    builder: (context, state) => WorkspaceDetailPage(
                      workspaceId: state.pathParameters['workspaceId']!,
                    ),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.workspaces, AppRoutes.workspaceMembers)}/:workspaceId',
                    name: 'workspaceMembers',
                    builder: (context, state) => WorkspaceMembersPage(
                      workspaceId: state.pathParameters['workspaceId']!,
                    ),
                  ),
                  GoRoute(
                    path:
                        '${_subPath(AppRoutes.workspaces, AppRoutes.workspaceInvitations)}/:workspaceId',
                    name: 'workspaceInvitations',
                    builder: (context, state) => WorkspaceInvitationsPage(
                      workspaceId: state.pathParameters['workspaceId']!,
                    ),
                  ),
                  GoRoute(
                    path: _subPath(
                        AppRoutes.workspaces, AppRoutes.myInvitations),
                    name: 'myInvitations',
                    builder: (context, state) => const MyInvitationsPage(),
                  ),
                ],
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: _subPath(AppRoutes.profile, AppRoutes.profileEdit),
                    name: 'profileEdit',
                    builder: (context, state) => const ProfileEditPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bottom navigation shell holding the authenticated feature branches.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      navigationShell: navigationShell,
      selectedIndex: navigationShell.currentIndex,
    );
  }
}

/// Scaffold with the premium bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
    required this.selectedIndex,
  });

  final StatefulNavigationShell navigationShell;
  final int selectedIndex;

  /// One destination per shell branch, in branch order.
  static const List<_NavItem> destinations = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _NavItem(Icons.task_outlined, Icons.task, AppStrings.tasks),
    _NavItem(Icons.folder_outlined, Icons.folder, AppStrings.projects),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, AppStrings.calendar),
    _NavItem(Icons.people_outlined, Icons.people, 'Spaces'),
    _NavItem(Icons.person_outlined, Icons.person, 'You'),
  ];

  void _onTap(int index) {
    // Tapping the tab that is already open returns to the root of that tab.
    navigationShell.goBranch(index, initialLocation: index == selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      navigationShell.route.branches.length == destinations.length,
      'Every shell branch needs exactly one bottom navigation destination.',
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: _onTap,
            items: destinations
                .asMap()
                .entries
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: e.key == selectedIndex ? 28 : 24,
                      height: e.key == selectedIndex ? 28 : 24,
                      decoration: BoxDecoration(
                        color: e.key == selectedIndex
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        e.key == selectedIndex
                            ? e.value.selectedIcon
                            : e.value.icon,
                        size: e.key == selectedIndex ? 22 : 20,
                        color: e.key == selectedIndex
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .bottomNavigationBarTheme
                                .unselectedItemColor,
                      ),
                    ),
                    label: e.value.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
