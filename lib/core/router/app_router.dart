import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:flowtop/features/projects/presentation/pages/project_create_page.dart';
import 'package:flowtop/features/projects/presentation/pages/project_detail_page.dart';
import 'package:flowtop/features/projects/presentation/pages/project_list_page.dart';
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

/// Application router using GoRouter.
///
/// Redirect decisions are made synchronously via FirebaseAuth.instance.currentUser
/// so the router reacts to sign-in / sign-out without circular Riverpod dependencies.
/// The UI layer watches [authStateProvider] for reactive rebuilding.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: false,
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      final authPages = {
        AppRoutes.auth,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.resetPassword,
      };
      final isAuthPage = authPages.contains(location);
      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;

      // Signed out: send to sign-in (unless already on an auth page or splash).
      if (user == null && !isAuthPage && !isSplash && !isOnboarding) {
        return AppRoutes.signIn;
      }
      // Signed in: leave onboarding/auth pages behind, go to dashboard.
      if (user != null && (isAuthPage || isOnboarding)) {
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
      // Shell with bottom navigation for authenticated features.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Tasks branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.taskList,
                name: 'taskList',
                builder: (context, state) => const TaskListPage(),
              ),
              GoRoute(
                path: AppRoutes.taskCreate,
                name: 'taskCreate',
                builder: (context, state) => const TaskCreatePage(),
              ),
              GoRoute(
                path: '${AppRoutes.taskDetail}/:taskId',
                name: 'taskDetail',
                builder: (context, state) => TaskDetailPage(
                  taskId: state.pathParameters['taskId']!,
                ),
              ),
              GoRoute(
                path: '${AppRoutes.taskEdit}/:taskId',
                name: 'taskEdit',
                builder: (context, state) => TaskEditPage(
                  taskId: state.pathParameters['taskId']!,
                ),
              ),
            ],
          ),
          // Projects branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.projects,
                name: 'projects',
                builder: (context, state) => const ProjectListPage(),
              ),
              GoRoute(
                path: '${AppRoutes.projectDetail}/:projectId',
                name: 'projectDetail',
                builder: (context, state) => ProjectDetailPage(
                  projectId: state.pathParameters['projectId']!,
                ),
              ),
              GoRoute(
                path: AppRoutes.projectCreate,
                name: 'projectCreate',
                builder: (context, state) => const ProjectCreatePage(),
              ),
            ],
          ),
          // Calendar branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          // Workspaces branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workspaces,
                name: 'workspaces',
                builder: (context, state) => const WorkspaceListPage(),
              ),
              GoRoute(
                path: '${AppRoutes.workspaceDetail}/:workspaceId',
                name: 'workspaceDetail',
                builder: (context, state) => WorkspaceDetailPage(
                  workspaceId: state.pathParameters['workspaceId']!,
                ),
              ),
              GoRoute(
                path: AppRoutes.workspaceCreate,
                name: 'workspaceCreate',
                builder: (context, state) => const WorkspaceCreatePage(),
              ),
              GoRoute(
                path: '${AppRoutes.workspaceMembers}/:workspaceId',
                name: 'workspaceMembers',
                builder: (context, state) => WorkspaceMembersPage(
                  workspaceId: state.pathParameters['workspaceId']!,
                ),
              ),
              GoRoute(
                path: '${AppRoutes.workspaceInvitations}/:workspaceId',
                name: 'workspaceInvitations',
                builder: (context, state) => WorkspaceInvitationsPage(
                  workspaceId: state.pathParameters['workspaceId']!,
                ),
              ),
            ],
          ),
          // Statistics branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                name: 'statistics',
                builder: (context, state) => const StatisticsPage(),
              ),
            ],
          ),
          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bottom navigation shell holding the authenticated feature branches.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;

    return ScaffoldWithNavBar(
      navigationShell: navigationShell,
      selectedIndex: index,
    );
  }
}

/// Scaffold with the premium bottom navigation bar.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
    required this.selectedIndex,
  });

  final StatefulNavigationShell navigationShell;
  final int selectedIndex;

  static const List<_NavItem> _items = [
    _NavItem(AppRoutes.dashboard, Icons.dashboard_outlined, Icons.dashboard, AppStrings.dashboard),
    _NavItem(AppRoutes.taskList, Icons.task_outlined, Icons.task, AppStrings.tasks),
    _NavItem(AppRoutes.projects, Icons.folder_outlined, Icons.folder, AppStrings.projects),
    _NavItem(AppRoutes.calendar, Icons.calendar_today_outlined, Icons.calendar_today, AppStrings.calendar),
    _NavItem(AppRoutes.workspaces, Icons.people_outlined, Icons.people, AppStrings.workspaces),
    _NavItem(AppRoutes.profile, Icons.person_outlined, Icons.person, AppStrings.profile),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == selectedIndex) return;
    navigationShell.goBranch(index, initialLocation: index == 0 ? AppRoutes.dashboard : null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: (i) => _onTap(context, i),
            items: _items
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
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
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
  const _NavItem(this.route, this.icon, this.selectedIcon, this.label);
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
